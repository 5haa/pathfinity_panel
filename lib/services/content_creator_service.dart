import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:path/path.dart' as path;

class ContentCreatorService {
  final SupabaseClient _supabase = Supabase.instance.client;

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

  // Create a new course
  Future<String?> createCourse({
    required String creatorId,
    required String title,
    required String description,
    String? categoryId,
    String? membershipType,
    String? difficulty,
  }) async {
    try {
      final response =
          await _supabase
              .from('courses')
              .insert({
                'creator_id': creatorId,
                'title': title,
                'description': description,
                'is_active': true,
                if (categoryId != null) 'category_id': categoryId,
                if (membershipType != null) 'membership_type': membershipType,
                if (difficulty != null) 'difficulty': difficulty,
              })
              .select('id')
              .single();

      return response['id'] as String?;
    } catch (e) {
      debugPrint('Error creating course: $e');
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
  }) async {
    try {
      await _supabase.from('course_changes').insert({
        'course_id': courseId,
        'title': title,
        'description': description,
        if (categoryId != null) 'category_id': categoryId,
      });
      return true;
    } catch (e) {
      debugPrint('Error requesting course changes: $e');
      return false;
    }
  }
}
