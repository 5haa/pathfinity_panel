class CompanyUser {
  final String id;
  final String companyName;
  final String email;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePictureUrl;

  CompanyUser({
    required this.id,
    required this.companyName,
    required this.email,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
    this.profilePictureUrl,
  });

  factory CompanyUser.fromJson(Map<String, dynamic> json) {
    return CompanyUser(
      id: json['id'],
      companyName: json['company_name'],
      email: json['email'],
      isApproved: json['is_approved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'email': email,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_picture_url': profilePictureUrl,
    };
  }

  CompanyUser copyWith({
    String? id,
    String? companyName,
    String? email,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePictureUrl,
  }) {
    return CompanyUser(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
