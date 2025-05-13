class Internship {
  final String id;
  final String companyId;
  final String title;
  final String description;
  final String duration;
  final List<String> skills;
  final bool? isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? rejectionReason;
  final bool isPaid;
  final String? city;

  Internship({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.duration,
    required this.skills,
    this.isApproved,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.rejectionReason,
    required this.isPaid,
    this.city,
  });

  factory Internship.fromJson(Map<String, dynamic> json) {
    return Internship(
      id: json['id'],
      companyId: json['company_id'],
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      skills: List<String>.from(json['skills']),
      isApproved: json['is_approved'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: json['is_active'] ?? true,
      rejectionReason: json['rejection_reason'],
      isPaid: json['is_paid'] ?? false,
      city: json['city'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'title': title,
      'description': description,
      'duration': duration,
      'skills': skills,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'rejection_reason': rejectionReason,
      'is_paid': isPaid,
      'city': city,
    };
  }

  Internship copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    String? duration,
    List<String>? skills,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? rejectionReason,
    bool? isPaid,
    String? city,
  }) {
    return Internship(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      skills: skills ?? this.skills,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isPaid: isPaid ?? this.isPaid,
      city: city ?? this.city,
    );
  }
}
