import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/admin_model.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:admin_panel/models/course_model.dart';
import 'package:admin_panel/models/course_change_model.dart';
import 'package:admin_panel/models/video_change_model.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all admin users
  Future<List<AdminUser>> getAllAdmins() async {
    try {
      final data = await _supabase.from('user_admins').select();
      return data.map((json) => AdminUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting admins: $e');
      return [];
    }
  }

  // Get all alumni users
  Future<List<AlumniUser>> getAllAlumni() async {
    try {
      final data = await _supabase.from('user_alumni').select();
      return data.map((json) => AlumniUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting alumni: $e');
      return [];
    }
  }

  // Get all company users
  Future<List<CompanyUser>> getAllCompanies() async {
    try {
      final data = await _supabase.from('user_companies').select();
      return data.map((json) => CompanyUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting companies: $e');
      return [];
    }
  }

  // Get all content creator users
  Future<List<ContentCreatorUser>> getAllContentCreators() async {
    try {
      final data = await _supabase.from('user_content_creators').select();
      return data.map((json) => ContentCreatorUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting content creators: $e');
      return [];
    }
  }

  // Approve an alumni user
  Future<bool> approveAlumni(String userId) async {
    try {
      await _supabase
          .from('user_alumni')
          .update({'is_approved': true})
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error approving alumni: $e');
      return false;
    }
  }

  // Approve a company user
  Future<bool> approveCompany(String userId) async {
    try {
      await _supabase
          .from('user_companies')
          .update({'is_approved': true})
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error approving company: $e');
      return false;
    }
  }

  // Approve a content creator user
  Future<bool> approveContentCreator(String userId) async {
    try {
      await _supabase
          .from('user_content_creators')
          .update({'is_approved': true})
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error approving content creator: $e');
      return false;
    }
  }

  // Get pending approval alumni
  Future<List<AlumniUser>> getPendingAlumni() async {
    try {
      final data = await _supabase
          .from('user_alumni')
          .select()
          .eq('is_approved', false);
      return data.map((json) => AlumniUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting pending alumni: $e');
      return [];
    }
  }

  // Get pending approval companies
  Future<List<CompanyUser>> getPendingCompanies() async {
    try {
      final data = await _supabase
          .from('user_companies')
          .select()
          .eq('is_approved', false);
      return data.map((json) => CompanyUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting pending companies: $e');
      return [];
    }
  }

  // Get pending approval content creators
  Future<List<ContentCreatorUser>> getPendingContentCreators() async {
    try {
      final data = await _supabase
          .from('user_content_creators')
          .select()
          .eq('is_approved', false);
      return data.map((json) => ContentCreatorUser.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting pending content creators: $e');
      return [];
    }
  }

  // Create a new alumni user
  Future<bool> createAlumni({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return false;
      }

      // Add user to alumni table
      await _supabase.from('user_alumni').insert({
        'id': authResponse.user!.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'is_approved': true, // Auto-approve when created by admin
      });
      return true;
    } catch (e) {
      debugPrint('Error creating alumni: $e');
      return false;
    }
  }

  // Create a new company user
  Future<bool> createCompany({
    required String email,
    required String companyName,
    required String password,
  }) async {
    try {
      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return false;
      }

      // Add user to companies table
      await _supabase.from('user_companies').insert({
        'id': authResponse.user!.id,
        'email': email,
        'company_name': companyName,
        'is_approved': true, // Auto-approve when created by admin
      });
      return true;
    } catch (e) {
      debugPrint('Error creating company: $e');
      return false;
    }
  }

  // Create a new content creator user
  Future<bool> createContentCreator({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      // Create auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return false;
      }

      // Add user to content creators table
      await _supabase.from('user_content_creators').insert({
        'id': authResponse.user!.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'is_approved': true, // Auto-approve when created by admin
      });
      return true;
    } catch (e) {
      debugPrint('Error creating content creator: $e');
      return false;
    }
  }

  // Get all courses with category and creator information
  Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      final data = await _supabase
          .from('courses')
          .select('''
            *,
            course_categories(*),
            creator:creator_id(
              id,
              first_name,
              last_name,
              email
            )
          ''')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getting courses: $e');
      return [];
    }
  }

  // Get course details with videos
  Future<Map<String, dynamic>?> getCourseWithVideos(String courseId) async {
    try {
      final List<dynamic> result = await _supabase
          .from('courses')
          .select('''
            *,
            course_categories(*),
            creator:creator_id(
              id,
              first_name,
              last_name,
              email
            ),
            course_videos(*)
          ''')
          .eq('id', courseId)
          .order('created_at', ascending: false);

      if (result.isEmpty) {
        return null;
      }

      return Map<String, dynamic>.from(result.first);
    } catch (e) {
      debugPrint('Error getting course with videos: $e');
      return null;
    }
  }

  // Get pending course changes
  Future<List<Map<String, dynamic>>> getPendingCourseChanges() async {
    try {
      final data = await _supabase
          .from('course_changes')
          .select('''
            *,
            course:course_id(
              id,
              title,
              description,
              creator_id,
              category_id,
              course_categories(*),
              creator:creator_id(
                id,
                first_name,
                last_name,
                email
              )
            )
          ''')
          .eq('is_reviewed', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getting pending course changes: $e');
      return [];
    }
  }

  // Get pending video changes
  Future<List<Map<String, dynamic>>> getPendingVideoChanges() async {
    try {
      final data = await _supabase
          .from('video_changes')
          .select('''
            *,
            course_video:course_video_id(
              id,
              course_id,
              title,
              description,
              video_url,
              thumbnail_url,
              is_free_preview,
              course:course_id(
                id,
                title,
                creator_id,
                creator:creator_id(
                  id,
                  first_name,
                  last_name,
                  email
                )
              )
            )
          ''')
          .eq('is_reviewed', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getting pending video changes: $e');
      return [];
    }
  }

  // Approve a course change
  Future<bool> approveCourseChange(String courseChangeId) async {
    try {
      // First, get the change details
      final List<dynamic> result = await _supabase
          .from('course_changes')
          .select('*')
          .eq('id', courseChangeId);

      if (result.isEmpty) {
        return false;
      }

      final courseChange = Map<String, dynamic>.from(result.first);
      final courseId = courseChange['course_id'];

      // Update course with the changes
      final updateData = <String, dynamic>{};
      if (courseChange['title'] != null)
        updateData['title'] = courseChange['title'];
      if (courseChange['description'] != null)
        updateData['description'] = courseChange['description'];
      if (courseChange['category_id'] != null)
        updateData['category_id'] = courseChange['category_id'];

      // Update approval status
      updateData['is_approved'] = true;
      updateData['rejection_reason'] =
          null; // Clear any previous rejection reason

      // Update the course
      await _supabase.from('courses').update(updateData).eq('id', courseId);

      // Mark the change as reviewed and approved
      await _supabase
          .from('course_changes')
          .update({'is_reviewed': true, 'is_approved': true})
          .eq('id', courseChangeId);

      return true;
    } catch (e) {
      debugPrint('Error approving course change: $e');
      return false;
    }
  }

  // Reject a course change
  Future<bool> rejectCourseChange(String courseChangeId, String reason) async {
    try {
      // First, get the change details
      final List<dynamic> result = await _supabase
          .from('course_changes')
          .select('*')
          .eq('id', courseChangeId);

      if (result.isEmpty) {
        return false;
      }

      final courseChange = Map<String, dynamic>.from(result.first);

      // Mark the change as reviewed and rejected - no need to modify the course itself
      await _supabase
          .from('course_changes')
          .update({
            'is_reviewed': true,
            'is_approved': false,
            'rejection_reason': reason,
          })
          .eq('id', courseChangeId);

      return true;
    } catch (e) {
      debugPrint('Error rejecting course change: $e');
      return false;
    }
  }

  // Approve a video change
  Future<bool> approveVideoChange(String videoChangeId) async {
    try {
      // First, get the change details
      final List<dynamic> result = await _supabase
          .from('video_changes')
          .select('*')
          .eq('id', videoChangeId);

      if (result.isEmpty) {
        return false;
      }

      final videoChange = Map<String, dynamic>.from(result.first);
      final courseVideoId = videoChange['course_video_id'];

      // Update video with the changes
      final updateData = <String, dynamic>{};
      if (videoChange['title'] != null)
        updateData['title'] = videoChange['title'];
      if (videoChange['description'] != null)
        updateData['description'] = videoChange['description'];
      if (videoChange['video_url'] != null)
        updateData['video_url'] = videoChange['video_url'];
      if (videoChange['thumbnail_url'] != null)
        updateData['thumbnail_url'] = videoChange['thumbnail_url'];
      if (videoChange['is_free_preview'] != null)
        updateData['is_free_preview'] = videoChange['is_free_preview'];

      // Update approval status
      updateData['is_reviewed'] = true;
      updateData['is_approved'] = true;
      updateData['rejection_reason'] =
          null; // Clear any previous rejection reason

      // Update the video
      await _supabase
          .from('course_videos')
          .update(updateData)
          .eq('id', courseVideoId);

      // Mark the change as reviewed and approved
      await _supabase
          .from('video_changes')
          .update({'is_reviewed': true, 'is_approved': true})
          .eq('id', videoChangeId);

      return true;
    } catch (e) {
      debugPrint('Error approving video change: $e');
      return false;
    }
  }

  // Reject a video change
  Future<bool> rejectVideoChange(String videoChangeId, String reason) async {
    try {
      // First, get the change details
      final List<dynamic> result = await _supabase
          .from('video_changes')
          .select('*')
          .eq('id', videoChangeId);

      if (result.isEmpty) {
        return false;
      }

      final videoChange = Map<String, dynamic>.from(result.first);

      // Mark the change as reviewed and rejected - no need to modify the video itself
      await _supabase
          .from('video_changes')
          .update({
            'is_reviewed': true,
            'is_approved': false,
            'rejection_reason': reason,
          })
          .eq('id', videoChangeId);

      return true;
    } catch (e) {
      debugPrint('Error rejecting video change: $e');
      return false;
    }
  }

  // Approve a course
  Future<bool> approveCourse(String courseId) async {
    try {
      // First approve the course
      await _supabase
          .from('courses')
          .update({'is_approved': true})
          .eq('id', courseId);

      // Then approve only videos that currently exist in this course
      // This won't affect videos added after the course is approved
      await _supabase
          .from('course_videos')
          .update({
            'is_approved': true,
            'is_reviewed': true,
            'rejection_reason': null,
          })
          .eq('course_id', courseId)
          .eq(
            'is_reviewed',
            false,
          ); // Only approve videos that haven't been reviewed yet

      // Check for any pending course changes and apply them
      final List<dynamic> pendingChanges = await _supabase
          .from('course_changes')
          .select()
          .eq('course_id', courseId)
          .eq('is_reviewed', false)
          .order('created_at', ascending: false);

      if (pendingChanges.isNotEmpty) {
        // Get the most recent change
        final latestChange = pendingChanges.first;
        final changeId = latestChange['id'] as String;

        // Approve the change which will apply its changes to the course
        await approveCourseChange(changeId);
      }

      return true;
    } catch (e) {
      debugPrint('Error approving course: $e');
      return false;
    }
  }

  // Reject a course with a reason
  Future<bool> rejectCourse(String courseId, String reason) async {
    try {
      await _supabase
          .from('courses')
          .update({
            'is_approved': false,
            'is_reviewed': true,
            'rejection_reason': reason,
          })
          .eq('id', courseId);
      return true;
    } catch (e) {
      debugPrint('Error rejecting course: $e');
      return false;
    }
  }

  // Get student statistics (total and pro members)
  Future<Map<String, dynamic>> getStudentStatistics() async {
    try {
      // Get total students count
      final totalStudentsResult = await _supabase
          .from('user_students')
          .select('id, premium, premium_expires_at');

      final totalStudents = totalStudentsResult.length;

      // Count premium students (considering expiration date)
      int proStudents = 0;

      for (var student in totalStudentsResult) {
        bool isPremium = student['premium'] ?? false;
        String? expiresAt = student['premium_expires_at'];

        if (isPremium) {
          // Check if premium is still valid
          if (expiresAt == null) {
            // No expiration date means permanent premium
            proStudents++;
          } else {
            // Check if premium hasn't expired
            final expiryDate = DateTime.parse(expiresAt);
            if (expiryDate.isAfter(DateTime.now())) {
              proStudents++;
            }
          }
        }
      }

      return {
        'totalStudents': totalStudents,
        'proStudents': proStudents,
        'freeStudents': totalStudents - proStudents,
        'proPercentage':
            totalStudents > 0
                ? (proStudents / totalStudents * 100).toStringAsFixed(1)
                : '0',
      };
    } catch (e) {
      debugPrint('Error getting student statistics: $e');
      return {
        'totalStudents': 0,
        'proStudents': 0,
        'freeStudents': 0,
        'proPercentage': '0',
      };
    }
  }

  // Get all students
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final data = await _supabase.from('user_students').select();
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getting students: $e');
      return [];
    }
  }

  // Get all internships with company information
  Future<List<Map<String, dynamic>>> getAllInternships() async {
    try {
      final data = await _supabase
          .from('internships')
          .select('''
            *,
            company:company_id(
              id,
              company_name,
              email
            )
          ''')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getting internships: $e');
      return [];
    }
  }

  // Approve an internship
  Future<bool> approveInternship(String internshipId) async {
    try {
      await _supabase
          .from('internships')
          .update({'is_approved': true})
          .eq('id', internshipId);
      return true;
    } catch (e) {
      debugPrint('Error approving internship: $e');
      return false;
    }
  }

  // Reject an internship with a reason
  Future<bool> rejectInternship(String internshipId, String reason) async {
    try {
      await _supabase
          .from('internships')
          .update({'is_approved': false, 'rejection_reason': reason})
          .eq('id', internshipId);
      return true;
    } catch (e) {
      debugPrint('Error rejecting internship: $e');
      return false;
    }
  }

  // Approve a course video
  Future<bool> approveCourseVideo(String videoId) async {
    try {
      await _supabase
          .from('course_videos')
          .update({
            'is_approved': true,
            'is_reviewed': true,
            'rejection_reason': null, // Clear any previous rejection reason
          })
          .eq('id', videoId);
      return true;
    } catch (e) {
      debugPrint('Error approving course video: $e');
      return false;
    }
  }

  // Reject a course video with a reason
  Future<bool> rejectCourseVideo(String videoId, String reason) async {
    try {
      await _supabase
          .from('course_videos')
          .update({
            'is_approved': false,
            'is_reviewed': true,
            'rejection_reason': reason,
          })
          .eq('id', videoId);
      return true;
    } catch (e) {
      debugPrint('Error rejecting course video: $e');
      return false;
    }
  }

  // Toggle course active status
  Future<bool> toggleCourseActiveStatus(String courseId, bool isActive) async {
    try {
      await _supabase
          .from('courses')
          .update({'is_active': isActive})
          .eq('id', courseId);
      return true;
    } catch (e) {
      debugPrint('Error updating course active status: $e');
      return false;
    }
  }

  // Toggle internship active status
  Future<bool> toggleInternshipActiveStatus(
    String internshipId,
    bool isActive,
  ) async {
    try {
      await _supabase
          .from('internships')
          .update({'is_active': isActive})
          .eq('id', internshipId);
      return true;
    } catch (e) {
      debugPrint('Error updating internship active status: $e');
      return false;
    }
  }

  // Get pending videos count for courses
  Future<Map<String, int>> getPendingVideosCountByCourse() async {
    try {
      final data = await _supabase
          .from('course_videos')
          .select('course_id, id')
          .eq('is_reviewed', false);

      final Map<String, int> pendingVideosCounts = {};

      // Group videos by course_id
      for (var video in data) {
        final String courseId = video['course_id'] as String;
        pendingVideosCounts[courseId] =
            (pendingVideosCounts[courseId] ?? 0) + 1;
      }

      return pendingVideosCounts;
    } catch (e) {
      debugPrint('Error getting pending videos count: $e');
      return {};
    }
  }

  // Get pending video changes count for courses
  Future<Map<String, int>> getPendingVideoChangesCountByCourse() async {
    try {
      final data = await _supabase
          .from('video_changes')
          .select('''
            id,
            course_video:course_video_id(
              course_id
            )
          ''')
          .eq('is_reviewed', false);

      final Map<String, int> pendingVideoChangesCounts = {};

      // Group video changes by course_id
      for (var videoChange in data) {
        if (videoChange['course_video'] != null) {
          final String courseId =
              videoChange['course_video']['course_id'] as String;
          pendingVideoChangesCounts[courseId] =
              (pendingVideoChangesCounts[courseId] ?? 0) + 1;
        }
      }

      return pendingVideoChangesCounts;
    } catch (e) {
      debugPrint('Error getting pending video changes count: $e');
      return {};
    }
  }
}
