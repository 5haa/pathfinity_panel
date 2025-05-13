import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/admin_model.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:admin_panel/models/course_model.dart';

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

  // Approve a course
  Future<bool> approveCourse(String courseId) async {
    try {
      await _supabase
          .from('courses')
          .update({'is_approved': true})
          .eq('id', courseId);
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
          .update({'is_approved': false, 'rejection_reason': reason})
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
}
