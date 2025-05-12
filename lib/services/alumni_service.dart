import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/alumni_model.dart';

class AlumniService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get alumni profile by ID
  Future<AlumniUser?> getAlumniProfile(String userId) async {
    try {
      final data =
          await _supabase
              .from('user_alumni')
              .select()
              .eq('id', userId)
              .single();
      return AlumniUser.fromJson(data);
    } catch (e) {
      debugPrint('Error getting alumni profile: $e');
      return null;
    }
  }

  // Update alumni profile
  Future<bool> updateProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    DateTime? birthdate,
    int? graduationYear,
    String? university,
    String? experience,
  }) async {
    try {
      await _supabase
          .from('user_alumni')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'birthdate': birthdate?.toIso8601String(),
            'graduation_year': graduationYear,
            'university': university,
            'experience': experience,
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating alumni profile: $e');
      return false;
    }
  }

  // Check if alumni is approved
  Future<bool> isApproved(String userId) async {
    try {
      final data =
          await _supabase
              .from('user_alumni')
              .select('is_approved')
              .eq('id', userId)
              .single();
      return data['is_approved'] ?? false;
    } catch (e) {
      debugPrint('Error checking alumni approval status: $e');
      return false;
    }
  }
}
