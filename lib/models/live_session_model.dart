class LiveSession {
  final String id;
  final String creatorId;
  final String courseId;
  final String title;
  final String status; // 'scheduled', 'active', 'ended', or 'cancelled'
  final String channelName;
  final DateTime? scheduledAt;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int viewerCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  LiveSession({
    required this.id,
    required this.creatorId,
    required this.courseId,
    required this.title,
    required this.status,
    required this.channelName,
    this.scheduledAt,
    required this.startedAt,
    this.endedAt,
    required this.viewerCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'],
      creatorId: json['creator_id'],
      courseId: json['course_id'],
      title: json['title'],
      status: json['status'],
      channelName: json['channel_name'],
      scheduledAt:
          json['scheduled_at'] != null
              ? DateTime.parse(json['scheduled_at'])
              : null,
      startedAt: DateTime.parse(json['started_at']),
      endedAt:
          json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      viewerCount: json['viewer_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'course_id': courseId,
      'title': title,
      'status': status,
      'channel_name': channelName,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'viewer_count': viewerCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  LiveSession copyWith({
    String? id,
    String? creatorId,
    String? courseId,
    String? title,
    String? status,
    String? channelName,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    int? viewerCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiveSession(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      status: status ?? this.status,
      channelName: channelName ?? this.channelName,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      viewerCount: viewerCount ?? this.viewerCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
