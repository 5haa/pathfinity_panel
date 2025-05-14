import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ContentCreatorService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _courseThumbnailBucketName = 'course-thumbnails';
  final Uuid _uuid = const Uuid();

  // Get content creator profile by ID
  Future<ContentCreatorUser?> getContentCreatorProfile(String userId) async {
    try {
      final data =
          await _supabase
              .from('user_content_creators')
              .select()
              .eq('id', userId)
              .single();
      return ContentCreatorUser.fromJson(data);
    } catch (e) {
      debugPrint('Error getting content creator profile: $e');
      return null;
    }
  }

  // Update content creator profile
  Future<bool> updateProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    DateTime? birthdate,
    String? bio,
    String? phone,
  }) async {
    try {
      await _supabase
          .from('user_content_creators')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            if (birthdate != null) 'birthdate': birthdate.toIso8601String(),
            if (bio != null) 'bio': bio,
            if (phone != null) 'phone': phone,
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating content creator profile: $e');
      return false;
    }
  }

  // Check if content creator is approved
  Future<bool> isApproved(String userId) async {
    try {
      final data =
          await _supabase
              .from('user_content_creators')
              .select('is_approved')
              .eq('id', userId)
              .single();
      return data['is_approved'] ?? false;
    } catch (e) {
      debugPrint('Error checking content creator approval status: $e');
      return false;
    }
  }

  // Upload a thumbnail image to Supabase storage
  Future<String?> uploadCourseThumbnail(
    File thumbnailFile,
    String creatorId,
  ) async {
    try {
      final fileExtension = path.extension(thumbnailFile.path);
      final fileName = 'thumbnail_${_uuid.v4()}$fileExtension';
      final filePath = '$creatorId/$fileName';

      if (!await thumbnailFile.exists()) {
        debugPrint(
          'Error: The source thumbnail file does not exist at path: ${thumbnailFile.path}',
        );
        return null;
      }

      try {
        await _supabase.storage
            .from(_courseThumbnailBucketName)
            .upload(
              filePath,
              thumbnailFile,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );
      } on StorageException catch (e) {
        debugPrint(
          'StorageException during thumbnail upload: ${e.message}, StatusCode: ${e.statusCode}',
        );
        if (e.statusCode == '404' && e.message.contains('Bucket not found')) {
          debugPrint(
            'The storage bucket "$_courseThumbnailBucketName" does not exist. Please create it in your Supabase dashboard.',
          );
        }
        return null;
      }

      // Return the public URL for the uploaded thumbnail
      final String publicUrl = _supabase.storage
          .from(_courseThumbnailBucketName)
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading course thumbnail: $e');
      return null;
    }
  }

  // Delete a thumbnail from storage
  Future<bool> deleteCourseThumbnailFromStorage(String thumbnailUrl) async {
    if (thumbnailUrl.isEmpty || !Uri.parse(thumbnailUrl).isAbsolute) {
      debugPrint('Invalid or empty thumbnail URL for deletion: $thumbnailUrl');
      return false;
    }
    try {
      // Extract path from URL
      final uri = Uri.parse(thumbnailUrl);
      // We need the path after the bucket name: creatorId/thumbnail_name.ext
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(_courseThumbnailBucketName);

      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        debugPrint('Invalid thumbnail URL format for deletion: $thumbnailUrl');
        return false;
      }

      // Join all segments after the bucket name
      final pathInBucket = pathSegments.sublist(bucketIndex + 1).join('/');

      await _supabase.storage.from(_courseThumbnailBucketName).remove([
        pathInBucket,
      ]);
      return true;
    } catch (e) {
      debugPrint('Error deleting thumbnail from storage: $e');
      return false;
    }
  }

  // Create a new course with thumbnail
  Future<String?> createCourseWithThumbnail({
    required String creatorId,
    required String title,
    required String description,
    File? thumbnailFile,
    String? categoryId,
    String? membershipType,
    String? difficulty,
  }) async {
    // Upload thumbnail if provided
    String? thumbnailUrl;
    if (thumbnailFile != null) {
      thumbnailUrl = await uploadCourseThumbnail(thumbnailFile, creatorId);
      if (thumbnailUrl == null) {
        debugPrint(
          'Thumbnail upload failed, but continuing with course creation.',
        );
      }
    }

    try {
      final response =
          await _supabase
              .from('courses')
              .insert({
                'creator_id': creatorId,
                'title': title,
                'description': description,
                'is_active': true,
                if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
                if (categoryId != null) 'category_id': categoryId,
                if (membershipType != null) 'membership_type': membershipType,
                if (difficulty != null) 'difficulty': difficulty,
              })
              .select('id')
              .single();

      return response['id'] as String?;
    } catch (e) {
      debugPrint('Error creating course: $e');
      // If we uploaded a thumbnail but the course creation failed, clean up
      if (thumbnailUrl != null) {
        await deleteCourseThumbnailFromStorage(thumbnailUrl);
      }
      return null;
    }
  }

  // Get content creator's courses
  Future<List<Map<String, dynamic>>> getCreatorCourses(String creatorId) async {
    try {
      final data = await _supabase
          .from('courses')
          .select('*, course_categories(*)')
          .eq('creator_id', creatorId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getting creator courses: $e');
      return [];
    }
  }

  // Request course changes
  Future<bool> requestCourseChanges({
    required String courseId,
    required String title,
    required String description,
    String? categoryId,
    File? thumbnailFile,
    String? creatorId,
    String? currentThumbnailUrl,
  }) async {
    // Handle thumbnail update if provided
    String? newThumbnailUrl;
    if (thumbnailFile != null && creatorId != null) {
      newThumbnailUrl = await uploadCourseThumbnail(thumbnailFile, creatorId);

      // Delete old thumbnail if new one was uploaded successfully
      if (newThumbnailUrl != null &&
          currentThumbnailUrl != null &&
          currentThumbnailUrl.isNotEmpty) {
        await deleteCourseThumbnailFromStorage(currentThumbnailUrl);
      }
    }

    try {
      // Either update the course directly or create a change request based on your app's workflow
      // This example updates the course directly including the thumbnail
      await _supabase
          .from('courses')
          .update({
            'title': title,
            'description': description,
            if (categoryId != null) 'category_id': categoryId,
            if (newThumbnailUrl != null) 'thumbnail_url': newThumbnailUrl,
          })
          .eq('id', courseId);

      return true;
    } catch (e) {
      debugPrint('Error updating course: $e');
      // If we uploaded a new thumbnail but the update failed, clean up
      if (newThumbnailUrl != null) {
        await deleteCourseThumbnailFromStorage(newThumbnailUrl);
      }
      return false;
    }
  }
}
