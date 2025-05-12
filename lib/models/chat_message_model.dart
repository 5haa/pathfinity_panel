import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/models/student_profile_model.dart';

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic senderProfile; // Can be AlumniUser or StudentProfile

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.senderProfile,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    dynamic profile;
    if (json['sender_profile'] != null) {
      // Determine the type of sender profile based on available data
      if (json['sender_profile']['graduation_year'] != null) {
        // This is likely an alumni profile
        profile = AlumniUser.fromJson(json['sender_profile']);
      } else {
        // This is likely a student profile
        profile = StudentProfile.fromJson(json['sender_profile']);
      }
    }

    return ChatMessage(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      senderProfile: profile,
    );
  }

  String get senderName {
    if (senderProfile == null) return 'Unknown User';

    if (senderProfile is StudentProfile) {
      return senderProfile.fullName;
    } else if (senderProfile is AlumniUser) {
      return '${senderProfile.firstName} ${senderProfile.lastName}';
    }

    return 'Unknown User';
  }

  String? get senderProfilePictureUrl {
    if (senderProfile == null) return null;

    if (senderProfile is StudentProfile) {
      return senderProfile.profilePictureUrl;
    } else if (senderProfile is AlumniUser) {
      return senderProfile.profilePictureUrl;
    }

    return null;
  }

  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }
}
