class StudentProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final DateTime? birthdate;
  final String? gender;
  final bool premium;
  final DateTime? premiumExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePictureUrl;
  final List<String> skills;

  StudentProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.birthdate,
    this.gender,
    required this.premium,
    this.premiumExpiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.profilePictureUrl,
    this.skills = const [],
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      birthdate:
          json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      gender: json['gender'],
      premium: json['premium'] ?? false,
      premiumExpiresAt:
          json['premium_expires_at'] != null
              ? DateTime.parse(json['premium_expires_at'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      profilePictureUrl: json['profile_picture_url'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
    );
  }

  String get fullName => '$firstName $lastName';
}
