import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:admin_panel/services/auth_service.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  final String _bucketName = 'profile-pictures';

  // Get folder name based on user type
  String _getFolderName(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'admin';
      case UserType.alumni:
        return 'alumni';
      case UserType.company:
        return 'company';
      case UserType.contentCreator:
        return 'content_creator';
      default:
        return 'unknown';
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture(
    String userId,
    File imageFile,
    UserType userType,
  ) async {
    try {
      final folderName = _getFolderName(userType);
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${_uuid.v4()}$fileExtension';
      final filePath = '$folderName/$userId/$fileName';

      // Upload file to Supabase Storage
      await _supabase.storage
          .from(_bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final imageUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      // Update user profile with the new image URL
      await _updateUserProfilePicture(userId, userType, imageUrl);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  // Get profile picture URL
  String? getProfilePictureUrl(
    String userId,
    UserType userType,
    String? existingUrl,
  ) {
    // If there's already a URL, return it
    if (existingUrl != null && existingUrl.isNotEmpty) {
      return existingUrl;
    }

    // Otherwise, try to construct a URL based on the user ID and type
    try {
      final folderName = _getFolderName(userType);
      final filePath = '$folderName/$userId.jpg'; // Assuming jpg as default
      return _supabase.storage.from(_bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Error getting profile picture URL: $e');
      return null;
    }
  }

  // Delete profile picture
  Future<bool> deleteProfilePicture(String userId, UserType userType) async {
    try {
      final folderName = _getFolderName(userType);

      // List files to find the correct one (regardless of extension)
      final List<FileObject> files = await _supabase.storage
          .from(_bucketName)
          .list(path: folderName);

      // Find files that start with the user ID
      final matchingFiles = files.where((file) => file.name.startsWith(userId));

      // Delete each matching file
      for (var file in matchingFiles) {
        await _supabase.storage.from(_bucketName).remove([
          '$folderName/${file.name}',
        ]);
      }

      // Update user profile to remove the image URL
      await _updateUserProfilePicture(userId, userType, null);

      return true;
    } catch (e) {
      debugPrint('Error deleting profile picture: $e');
      return false;
    }
  }

  // Update user profile with new profile picture URL
  Future<void> _updateUserProfilePicture(
    String userId,
    UserType userType,
    String? imageUrl,
  ) async {
    try {
      final table = _getTableName(userType);

      await _supabase
          .from(table)
          .update({
            'profile_picture_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating profile with picture URL: $e');
      rethrow;
    }
  }

  // Get table name based on user type
  String _getTableName(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'user_admins';
      case UserType.alumni:
        return 'user_alumni';
      case UserType.company:
        return 'user_companies';
      case UserType.contentCreator:
        return 'user_content_creators';
      default:
        throw Exception('Unknown user type');
    }
  }
}
