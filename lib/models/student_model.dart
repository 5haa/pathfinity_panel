import 'package:admin_panel/models/user_model.dart';

class StudentUser extends BaseUser {
  final String? firstName;
  final String? lastName;
  final DateTime? birthdate;
  final bool premium;
  final DateTime? premiumExpiresAt;
  final bool active;
  final String? gender;
  final List<String>? skills;
  final String? profilePictureUrl;

  StudentUser({
    required String id,
    required String email,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.firstName,
    this.lastName,
    this.birthdate,
    required this.premium,
    this.premiumExpiresAt,
    required this.active,
    this.gender,
    this.skills,
    this.profilePictureUrl,
  }) : super(
         id: id,
         email: email,
         userType: UserType.student,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  @override
  String get displayName => '$firstName ${lastName ?? ''}';

  bool get isPremiumActive {
    if (!premium) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      birthdate:
          json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      premium: json['premium'] ?? false,
      premiumExpiresAt:
          json['premium_expires_at'] != null
              ? DateTime.parse(json['premium_expires_at'])
              : null,
      active: json['active'] ?? true,
      gender: json['gender'],
      skills: json['skills'] != null ? List<String>.from(json['skills']) : null,
      profilePictureUrl: json['profile_picture_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'birthdate': birthdate?.toIso8601String(),
      'premium': premium,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'active': active,
      'gender': gender,
      'skills': skills,
      'profile_picture_url': profilePictureUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    return data;
  }

  StudentUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? birthdate,
    bool? premium,
    DateTime? premiumExpiresAt,
    bool? active,
    String? gender,
    List<String>? skills,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentUser(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthdate: birthdate ?? this.birthdate,
      premium: premium ?? this.premium,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      active: active ?? this.active,
      gender: gender ?? this.gender,
      skills: skills ?? this.skills,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
