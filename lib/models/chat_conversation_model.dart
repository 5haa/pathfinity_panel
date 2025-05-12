import 'package:admin_panel/models/chat_participant_model.dart';
import 'package:admin_panel/models/chat_message_model.dart';

class ChatConversation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatParticipant>? participants;
  final ChatMessage? lastMessage;

  ChatConversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.participants,
    this.lastMessage,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      participants:
          json['participants'] != null
              ? (json['participants'] as List)
                  .map((p) => ChatParticipant.fromJson(p))
                  .toList()
              : null,
      lastMessage:
          json['last_message'] != null
              ? ChatMessage.fromJson(json['last_message'])
              : null,
    );
  }

  // Get the other participant (not the current user)
  ChatParticipant? getOtherParticipant(String currentUserId) {
    if (participants == null || participants!.isEmpty) return null;
    try {
      return participants!.firstWhere((p) => p.userId != currentUserId);
    } catch (e) {
      // If no other participant is found, return the first one
      return participants!.first;
    }
  }
}
