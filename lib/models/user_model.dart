enum UserType { admin, alumni, company, contentCreator, student }

abstract class BaseUser {
  final String id;
  final String email;
  final UserType userType;
  final DateTime createdAt;
  final DateTime updatedAt;

  BaseUser({
    required this.id,
    required this.email,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName;

  Map<String, dynamic> toJson();
}
