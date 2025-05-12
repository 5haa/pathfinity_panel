class AdminUser {
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String? lastName;
  final bool isSuperAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePictureUrl;

  AdminUser({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    this.lastName,
    required this.isSuperAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.profilePictureUrl,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      isSuperAdmin: json['is_super_admin'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      profilePictureUrl: json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'is_super_admin': isSuperAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'profile_picture_url': profilePictureUrl,
    };
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? username,
    String? firstName,
    String? lastName,
    bool? isSuperAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePictureUrl,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }
}
