import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/models/student_profile_model.dart';

class ChatParticipant {
  final String id;
  final String conversationId;
  final String userId;
  final String userType; // 'alumni' or 'student'
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic userProfile; // Can be AlumniUser or StudentProfile

  ChatParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    this.userProfile,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    dynamic profile;
    if (json['user_profile'] != null) {
      if (json['user_type'] == 'student') {
        profile = StudentProfile.fromJson(json['user_profile']);
      } else if (json['user_type'] == 'alumni') {
        profile = AlumniUser.fromJson(json['user_profile']);
      }
    }

    return ChatParticipant(
      id: json['id'],
      conversationId: json['conversation_id'],
      userId: json['user_id'],
      userType: json['user_type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userProfile: profile,
    );
  }

  String get displayName {
    if (userProfile == null) return 'Unknown User';

    if (userType == 'student' && userProfile is StudentProfile) {
      return userProfile.fullName;
    } else if (userType == 'alumni' && userProfile is AlumniUser) {
      return '${userProfile.firstName} ${userProfile.lastName}';
    }

    return 'Unknown User';
  }

  String? get profilePictureUrl {
    if (userProfile == null) return null;

    if (userType == 'student' && userProfile is StudentProfile) {
      return userProfile.profilePictureUrl;
    } else if (userType == 'alumni' && userProfile is AlumniUser) {
      return userProfile.profilePictureUrl;
    }

    return null;
  }
}
