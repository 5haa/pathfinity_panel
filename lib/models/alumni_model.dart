class AlumniUser {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isApproved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? birthdate;
  final int? graduationYear;
  final String? university;
  final String? experience;
  final String? profilePictureUrl;

  AlumniUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
    this.birthdate,
    this.graduationYear,
    this.university,
    this.experience,
    this.profilePictureUrl,
  });

  factory AlumniUser.fromJson(Map<String, dynamic> json) {
    return AlumniUser(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      isApproved: json['is_approved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      birthdate:
          json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      graduationYear: json['graduation_year'],
      university: json['university'],
      experience: json['experience'],
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'birthdate': birthdate?.toIso8601String(),
      'graduation_year': graduationYear,
      'university': university,
      'experience': experience,
      'profile_picture_url': profilePictureUrl,
    };
  }

  AlumniUser copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    bool? isApproved,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? birthdate,
    int? graduationYear,
    String? university,
    String? experience,
    String? profilePictureUrl,
  }) {
    return AlumniUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      birthdate: birthdate ?? this.birthdate,
      graduationYear: graduationYear ?? this.graduationYear,
      university: university ?? this.university,
      experience: experience ?? this.experience,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
