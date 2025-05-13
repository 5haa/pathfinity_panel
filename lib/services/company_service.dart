import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/models/internship_model.dart';

class CompanyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get company profile by ID
  Future<CompanyUser?> getCompanyProfile(String userId) async {
    try {
      final data =
          await _supabase
              .from('user_companies')
              .select()
              .eq('id', userId)
              .single();
      return CompanyUser.fromJson(data);
    } catch (e) {
      debugPrint('Error getting company profile: $e');
      return null;
    }
  }

  // Update company profile
  Future<bool> updateProfile({
    required String userId,
    required String companyName,
    required String email,
  }) async {
    try {
      await _supabase
          .from('user_companies')
          .update({'company_name': companyName, 'email': email})
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating company profile: $e');
      return false;
    }
  }

  // Check if company is approved
  Future<bool> isApproved(String userId) async {
    try {
      final data =
          await _supabase
              .from('user_companies')
              .select('is_approved')
              .eq('id', userId)
              .single();
      return data['is_approved'] ?? false;
    } catch (e) {
      debugPrint('Error checking company approval status: $e');
      return false;
    }
  }

  // Create a new internship
  Future<bool> createInternship({
    required String companyId,
    required String title,
    required String description,
    required String duration,
    required List<String> skills,
    required bool isPaid,
    String? city,
  }) async {
    try {
      await _supabase.from('internships').insert({
        'company_id': companyId,
        'title': title,
        'description': description,
        'duration': duration,
        'skills': skills,
        'is_active': true,
        'is_paid': isPaid,
        'city': city,
      });
      return true;
    } catch (e) {
      debugPrint('Error creating internship: $e');
      return false;
    }
  }

  // Get company's internships
  Future<List<Internship>> getCompanyInternships(String companyId) async {
    try {
      final data = await _supabase
          .from('internships')
          .select()
          .eq('company_id', companyId);
      return data.map<Internship>((json) => Internship.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting company internships: $e');
      return [];
    }
  }

  // Update internship status (active/inactive)
  Future<bool> updateInternshipStatus({
    required String internshipId,
    required bool isActive,
  }) async {
    try {
      await _supabase
          .from('internships')
          .update({'is_active': isActive})
          .eq('id', internshipId);
      return true;
    } catch (e) {
      debugPrint('Error updating internship status: $e');
      return false;
    }
  }

  // Update internship details
  Future<bool> updateInternship({
    required String internshipId,
    required String title,
    required String description,
    required String duration,
    required List<String> skills,
    required bool isPaid,
    String? city,
  }) async {
    try {
      await _supabase
          .from('internships')
          .update({
            'title': title,
            'description': description,
            'duration': duration,
            'skills': skills,
            'is_paid': isPaid,
            'city': city,
          })
          .eq('id', internshipId);
      return true;
    } catch (e) {
      debugPrint('Error updating internship: $e');
      return false;
    }
  }

  // Delete an internship
  Future<bool> deleteInternship(String internshipId) async {
    try {
      await _supabase.from('internships').delete().eq('id', internshipId);
      return true;
    } catch (e) {
      debugPrint('Error deleting internship: $e');
      return false;
    }
  }
}
