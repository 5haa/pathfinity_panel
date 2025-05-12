class ContentCreatorUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime? birthdate;
  final String? bio;
  final String? phone;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePictureUrl;

  ContentCreatorUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.birthdate,
    this.bio,
    this.phone,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
    this.profilePictureUrl,
  });

  factory ContentCreatorUser.fromJson(Map<String, dynamic> json) {
    return ContentCreatorUser(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      birthdate:
          json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      bio: json['bio'],
      phone: json['phone']?.toString(),
      isApproved: json['is_approved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'birthdate': birthdate?.toIso8601String(),
      'bio': bio,
      'phone': phone,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_picture_url': profilePictureUrl,
    };
  }

  ContentCreatorUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? birthdate,
    String? bio,
    String? phone,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePictureUrl,
  }) {
    return ContentCreatorUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      birthdate: birthdate ?? this.birthdate,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
