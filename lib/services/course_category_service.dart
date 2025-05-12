import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/models/course_category_model.dart';

// Provider for CourseCategoryService
final courseCategoryServiceProvider = Provider<CourseCategoryService>((ref) {
  return CourseCategoryService();
});

class CourseCategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all categories
  Future<List<CourseCategory>> getAllCategories() async {
    try {
      final data = await _supabase
          .from('course_categories')
          .select()
          .order('name');

      return data
          .map<CourseCategory>((item) => CourseCategory.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  // Get category by ID
  Future<CourseCategory?> getCategoryById(String categoryId) async {
    try {
      final data =
          await _supabase
              .from('course_categories')
              .select()
              .eq('id', categoryId)
              .single();

      return CourseCategory.fromJson(data);
    } catch (e) {
      debugPrint('Error getting category by ID: $e');
      return null;
    }
  }

  // Create a new category (admin only)
  Future<CourseCategory?> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      final response =
          await _supabase
              .from('course_categories')
              .insert({'name': name, 'description': description})
              .select()
              .single();

      return CourseCategory.fromJson(response);
    } catch (e) {
      debugPrint('Error creating category: $e');
      return null;
    }
  }

  // Update a category (admin only)
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    String? description,
  }) async {
    try {
      await _supabase
          .from('course_categories')
          .update({'name': name, 'description': description})
          .eq('id', categoryId);

      return true;
    } catch (e) {
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  // Delete a category (admin only)
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _supabase.from('course_categories').delete().eq('id', categoryId);

      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return false;
    }
  }
}
