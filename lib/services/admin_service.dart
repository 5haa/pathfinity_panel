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

  // Create a new admin user (only super admins can do this)
  Future<bool> createAdmin({
    required String email,
    required String username,
    required String firstName,
    String? lastName,
    required bool isSuperAdmin,
  }) async {
    try {
      // This would typically involve creating a user in auth first
      // and then adding them to the admin table
      // For simplicity, we're just showing the admin table part
      await _supabase.from('user_admins').insert({
        'email': email,
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'is_super_admin': isSuperAdmin,
      });
      return true;
    } catch (e) {
      debugPrint('Error creating admin: $e');
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
}
