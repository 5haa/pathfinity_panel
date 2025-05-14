class VideoChange {
  final String id;
  final String courseVideoId;
  final String? title;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool? isFreePreview;
  final bool isReviewed;
  final bool? isApproved;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  VideoChange({
    required this.id,
    required this.courseVideoId,
    this.title,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.isFreePreview,
    this.isReviewed = false,
    this.isApproved,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoChange.fromJson(Map<String, dynamic> json) {
    return VideoChange(
      id: json['id'] as String,
      courseVideoId: json['course_video_id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      isFreePreview: json['is_free_preview'] as bool?,
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
      'course_video_id': courseVideoId,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'is_free_preview': isFreePreview,
      'is_reviewed': isReviewed,
      'is_approved': isApproved,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VideoChange copyWith({
    String? id,
    String? courseVideoId,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    bool? isFreePreview,
    bool? isReviewed,
    bool? isApproved,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoChange(
      id: id ?? this.id,
      courseVideoId: courseVideoId ?? this.courseVideoId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isFreePreview: isFreePreview ?? this.isFreePreview,
      isReviewed: isReviewed ?? this.isReviewed,
      isApproved: isApproved ?? this.isApproved,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
