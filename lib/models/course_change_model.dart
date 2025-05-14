import 'package:admin_panel/models/course_category_model.dart';

class CourseChange {
  final String id;
  final String courseId;
  final String? title;
  final String? description;
  final String? categoryId;
  final String? thumbnailUrl;
  final bool isReviewed;
  final bool? isApproved;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseChange({
    required this.id,
    required this.courseId,
    this.title,
    this.description,
    this.categoryId,
    this.thumbnailUrl,
    this.isReviewed = false,
    this.isApproved,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseChange.fromJson(Map<String, dynamic> json) {
    return CourseChange(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isReviewed: json['is_reviewed'] as bool? ?? false,
      isApproved: json['is_approved'] as bool?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'thumbnail_url': thumbnailUrl,
      'is_reviewed': isReviewed,
      'is_approved': isApproved,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CourseChange copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    String? categoryId,
    String? thumbnailUrl,
    bool? isReviewed,
    bool? isApproved,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseChange(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isReviewed: isReviewed ?? this.isReviewed,
      isApproved: isApproved ?? this.isApproved,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
