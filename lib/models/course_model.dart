import 'package:admin_panel/models/course_category_model.dart';

// Define membership type constants
class MembershipType {
  static const String free = 'FREE';
  static const String pro = 'PRO';
}

// Define difficulty level constants
class DifficultyLevel {
  static const String easy = 'easy';
  static const String medium = 'medium';
  static const String hard = 'hard';
}

class Course {
  final String id;
  final String title;
  final String? description;
  final String creatorId;
  final bool isApproved;
  final bool isActive;
  final String? rejectionReason;
  final String? categoryId;
  final CourseCategory? category;
  final String membershipType; // Added for course membership type
  final String difficulty; // Added for course difficulty level
  final String? thumbnailUrl; // Added for course thumbnail
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    this.description,
    required this.creatorId,
    this.isApproved = false,
    this.isActive = true,
    this.rejectionReason,
    this.categoryId,
    this.category,
    this.membershipType = MembershipType.pro, // Default to PRO
    this.difficulty = DifficultyLevel.medium, // Default to MEDIUM
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      creatorId: json['creator_id'] as String,
      isApproved: json['is_approved'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      rejectionReason: json['rejection_reason'] as String?,
      categoryId: json['category_id'] as String?,
      category:
          json['category'] != null
              ? CourseCategory.fromJson(
                json['category'] as Map<String, dynamic>,
              )
              : null,
      membershipType: json['membership_type'] as String? ?? MembershipType.pro,
      difficulty: json['difficulty'] as String? ?? DifficultyLevel.medium,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creator_id': creatorId,
      'is_approved': isApproved,
      'is_active': isActive,
      'rejection_reason': rejectionReason,
      'category_id': categoryId,
      'membership_type': membershipType,
      'difficulty': difficulty,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (category != null) 'category': category!.toJson(),
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorId,
    bool? isApproved,
    bool? isActive,
    String? rejectionReason,
    String? categoryId,
    CourseCategory? category,
    String? membershipType,
    String? difficulty,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      isApproved: isApproved ?? this.isApproved,
      isActive: isActive ?? this.isActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      membershipType: membershipType ?? this.membershipType,
      difficulty: difficulty ?? this.difficulty,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
