import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/student_profile_model.dart';

class StudentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all students
  Future<List<StudentProfile>> getAllStudents() async {
    try {
      final data = await _supabase
          .from('user_students')
          .select()
          .not('first_name', 'is', null)
          .not('last_name', 'is', null)
          .eq('active', true);

      return data
          .map<StudentProfile>((item) => StudentProfile.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting students: $e');
      return [];
    }
  }

  // Get student profile by ID
  Future<StudentProfile?> getStudentProfile(String studentId) async {
    try {
      final data =
          await _supabase
              .from('user_students')
              .select()
              .eq('id', studentId)
              .single();

      return StudentProfile.fromJson(data);
    } catch (e) {
      debugPrint('Error getting student profile: $e');
      return null;
    }
  }

  // Search students by name
  Future<List<StudentProfile>> searchStudents(String query) async {
    try {
      if (query.isEmpty) {
        return getAllStudents();
      }

      // Convert query to lowercase for case-insensitive search
      final lowerQuery = query.toLowerCase();

      // Get all students and filter locally
      // This is a simple approach - in a real app with many students,
      // you'd want to implement server-side search
      final allStudents = await getAllStudents();

      return allStudents.where((student) {
        final fullName =
            '${student.firstName} ${student.lastName}'.toLowerCase();
        return fullName.contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching students: $e');
      return [];
    }
  }

  // Get all unique skills from students
  Future<List<String>> getAllSkills() async {
    try {
      final List<StudentProfile> students = await getAllStudents();

      // Extract all skills and create a unique set
      final Set<String> uniqueSkills = {};
      for (final student in students) {
        uniqueSkills.addAll(student.skills);
      }

      return uniqueSkills.toList()..sort();
    } catch (e) {
      debugPrint('Error getting skills: $e');
      return [];
    }
  }

  // Filter students by skills
  Future<List<StudentProfile>> filterStudentsBySkills(
    List<String> selectedSkills,
  ) async {
    try {
      if (selectedSkills.isEmpty) {
        return getAllStudents();
      }

      final allStudents = await getAllStudents();

      return allStudents.where((student) {
        // Check if student has any of the selected skills
        for (final skill in selectedSkills) {
          if (student.skills.contains(skill)) {
            return true;
          }
        }
        return false;
      }).toList();
    } catch (e) {
      debugPrint('Error filtering students by skills: $e');
      return [];
    }
  }
}
