class CourseVideo {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl; // Added for video thumbnails
  final int sequenceNumber;
  final bool isReviewed;
  final bool? isApproved; // Nullable boolean
  final String? rejectionReason; // Nullable string
  final bool isFreePreview; // Added for free preview videos
  final DateTime createdAt;
  final DateTime updatedAt;

  CourseVideo({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.sequenceNumber,
    this.isReviewed = false,
    this.isApproved,
    this.rejectionReason,
    this.isFreePreview = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseVideo.fromJson(Map<String, dynamic> json) {
    return CourseVideo(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      sequenceNumber: json['sequence_number'] as int,
      isReviewed: json['is_reviewed'] ?? false,
      isApproved: json['is_approved'] as bool?,
      rejectionReason: json['rejection_reason'] as String?,
      isFreePreview: json['is_free_preview'] as bool? ?? false,
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
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'sequence_number': sequenceNumber,
      'is_reviewed': isReviewed,
      'is_approved': isApproved,
      'rejection_reason': rejectionReason,
      'is_free_preview': isFreePreview,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CourseVideo copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? sequenceNumber,
    bool? isReviewed,
    bool? isApproved,
    String? rejectionReason,
    bool? isFreePreview,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseVideo(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      isReviewed: isReviewed ?? this.isReviewed,
      isApproved: isApproved ?? this.isApproved,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isFreePreview: isFreePreview ?? this.isFreePreview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
