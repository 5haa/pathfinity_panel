import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/chat_conversation_model.dart';
import 'package:admin_panel/models/chat_message_model.dart';
import 'package:admin_panel/models/chat_participant_model.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/models/student_profile_model.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all conversations for the current alumni user
  Future<List<ChatConversation>> getConversations() async {
    try {
      // Get conversations where the current user is a participant
      final userId = _supabase.auth.currentUser!.id;

      final data = await _supabase
          .from('chat_participants')
          .select('conversation_id')
          .eq('user_id', userId);

      final conversationIds =
          data.map((item) => item['conversation_id']).toList();

      if (conversationIds.isEmpty) {
        return [];
      }

      final conversations = await _supabase
          .from('chat_conversations')
          .select()
          .inFilter('id', conversationIds)
          .order('updated_at', ascending: false);

      // Get participants for each conversation
      final result = await Future.wait(
        conversations.map((conv) async {
          final participants = await _supabase
              .from('chat_participants')
              .select()
              .eq('conversation_id', conv['id']);

          // Fetch user profiles for each participant
          final participantsWithProfiles = await Future.wait(
            participants.map((p) async {
              final userType = p['user_type'];
              final userId = p['user_id'];

              if (userType == 'student') {
                final studentData =
                    await _supabase
                        .from('user_students')
                        .select()
                        .eq('id', userId)
                        .maybeSingle();

                if (studentData != null) {
                  return {...p, 'user_profile': studentData};
                }
              } else if (userType == 'alumni') {
                final alumniData =
                    await _supabase
                        .from('user_alumni')
                        .select()
                        .eq('id', userId)
                        .maybeSingle();

                if (alumniData != null) {
                  return {...p, 'user_profile': alumniData};
                }
              }

              return p;
            }),
          );

          // Get the last message for the conversation
          final messages = await _supabase
              .from('chat_messages')
              .select()
              .eq('conversation_id', conv['id'])
              .order('created_at', ascending: false)
              .limit(1);

          final lastMessage = messages.isNotEmpty ? messages.first : null;

          return {
            ...conv,
            'participants': participantsWithProfiles,
            'last_message': lastMessage,
          };
        }),
      );

      return result.map((item) => ChatConversation.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      return [];
    }
  }

  // Get messages for a conversation
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final data = await _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at');

      // Fetch sender profiles for each message
      final messagesWithProfiles = await Future.wait(
        data.map((msg) async {
          final senderId = msg['sender_id'];

          // Check if sender is alumni
          final alumniData =
              await _supabase
                  .from('user_alumni')
                  .select()
                  .eq('id', senderId)
                  .maybeSingle();

          if (alumniData != null) {
            return {...msg, 'sender_profile': alumniData};
          }

          // Check if sender is student
          final studentData =
              await _supabase
                  .from('user_students')
                  .select()
                  .eq('id', senderId)
                  .maybeSingle();

          if (studentData != null) {
            return {...msg, 'sender_profile': studentData};
          }

          return msg;
        }),
      );

      return messagesWithProfiles
          .map((item) => ChatMessage.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  // Send a message
  Future<ChatMessage?> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final data =
          await _supabase
              .from('chat_messages')
              .insert({
                'conversation_id': conversationId,
                'sender_id': userId,
                'content': content,
              })
              .select()
              .single();

      // Update conversation's updated_at timestamp
      await _supabase
          .from('chat_conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);

      return ChatMessage.fromJson(data);
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  // Create a new conversation with a student
  Future<String?> createConversationWithStudent(String studentId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Check if a conversation already exists between these users
      final existingConversations = await _supabase
          .from('chat_participants')
          .select('conversation_id')
          .eq('user_id', userId);

      final existingConversationIds =
          existingConversations
              .map((item) => item['conversation_id'] as String)
              .toList();

      if (existingConversationIds.isNotEmpty) {
        final studentParticipants = await _supabase
            .from('chat_participants')
            .select('conversation_id')
            .eq('user_id', studentId)
            .inFilter('conversation_id', existingConversationIds);

        if (studentParticipants.isNotEmpty) {
          // Conversation already exists
          return studentParticipants.first['conversation_id'] as String;
        }
      }

      // Create a new conversation
      final conversationData =
          await _supabase
              .from('chat_conversations')
              .insert({})
              .select()
              .single();

      final conversationId = conversationData['id'] as String;

      // Add current user (alumni) as participant
      await _supabase.from('chat_participants').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'user_type': 'alumni',
      });

      // Add student as participant
      await _supabase.from('chat_participants').insert({
        'conversation_id': conversationId,
        'user_id': studentId,
        'user_type': 'student',
      });

      return conversationId;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      return false;
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Get conversations where the current user is a participant
      final participantData = await _supabase
          .from('chat_participants')
          .select('conversation_id')
          .eq('user_id', userId);

      final conversationIds =
          participantData
              .map((item) => item['conversation_id'] as String)
              .toList();

      if (conversationIds.isEmpty) {
        return 0;
      }

      final data = await _supabase
          .from('chat_messages')
          .select('id')
          .inFilter('conversation_id', conversationIds)
          .eq('is_read', false)
          .neq('sender_id', userId);

      return data.length;
    } catch (e) {
      debugPrint('Error getting unread message count: $e');
      return 0;
    }
  }

  // Listen for new messages in a conversation
  Stream<List<ChatMessage>> listenToMessages(String conversationId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data.map((item) => ChatMessage.fromJson(item)).toList());
  }
}
