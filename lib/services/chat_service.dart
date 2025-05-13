import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/chat_conversation_model.dart';
import 'package:admin_panel/models/chat_message_model.dart';
import 'package:admin_panel/models/chat_participant_model.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/models/student_profile_model.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all conversations for the specified alumni user or current user
  Future<List<Map<String, dynamic>>> getConversations([String? userId]) async {
    try {
      // Get conversations where the specified user or current user is a participant
      final currentUserId = userId ?? _supabase.auth.currentUser!.id;

      final data = await _supabase
          .from('chat_participants')
          .select('conversation_id')
          .eq('user_id', currentUserId);

      final conversationIds =
          data.map((item) => item['conversation_id']).toList();

      if (conversationIds.isEmpty) {
        return [];
      }

      // Get the conversations data with last messages
      final List<Map<String, dynamic>> result = [];

      for (final convId in conversationIds) {
        try {
          // Get the conversation
          final convData =
              await _supabase
                  .from('chat_conversations')
                  .select()
                  .eq('id', convId)
                  .single();

          // Get the other participant (student)
          final participantData =
              await _supabase
                  .from('chat_participants')
                  .select()
                  .eq('conversation_id', convId)
                  .neq('user_id', currentUserId)
                  .single();

          final studentId = participantData['user_id'];

          // Get student profile
          final studentData =
              await _supabase
                  .from('user_students')
                  .select()
                  .eq('id', studentId)
                  .single();

          // Get last message
          final messages = await _supabase
              .from('chat_messages')
              .select()
              .eq('conversation_id', convId)
              .order('created_at', ascending: false)
              .limit(1);

          final lastMessage = messages.isNotEmpty ? messages.first : null;

          // Get unread count - fix the query to ensure it returns proper results
          final unreadMessages = await _supabase
              .from('chat_messages')
              .select()
              .eq('conversation_id', convId)
              .eq('is_read', false)
              .neq('sender_id', currentUserId);

          final unreadCount = unreadMessages.length;

          result.add({
            'id': convId,
            'created_at': convData['created_at'],
            'updated_at': convData['updated_at'],
            'student_id': studentId,
            'student_first_name': studentData['first_name'] ?? '',
            'student_last_name': studentData['last_name'] ?? '',
            'student_profile_picture_url':
                studentData['profile_picture_url'] ?? '',
            'last_message': lastMessage != null ? lastMessage['content'] : null,
            'last_message_time':
                lastMessage != null ? lastMessage['created_at'] : null,
            'unread_count': unreadCount,
          });
        } catch (e) {
          debugPrint('Error processing conversation $convId: $e');
          // Skip this conversation if there's an error
          continue;
        }
      }

      // Sort by last message time
      result.sort((a, b) {
        final DateTime aTime;
        final DateTime bTime;

        try {
          aTime =
              a['last_message_time'] != null
                  ? DateTime.parse(a['last_message_time'])
                  : DateTime.parse(a['updated_at']);
        } catch (e) {
          return 1; // Move items with parsing errors to the end
        }

        try {
          bTime =
              b['last_message_time'] != null
                  ? DateTime.parse(b['last_message_time'])
                  : DateTime.parse(b['updated_at']);
        } catch (e) {
          return -1; // Move items with parsing errors to the end
        }

        return bTime.compareTo(aTime); // Latest first
      });

      return result;
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      return [];
    }
  }

  // Get available students for chat
  Future<List<Map<String, dynamic>>> getStudentsForChat() async {
    try {
      final studentsData = await _supabase
          .from('user_students')
          .select(
            'id, first_name, last_name, email, university, profile_picture_url, course:course_id(name)',
          )
          .eq('is_active', true);

      return studentsData.map((student) {
        return {
          'id': student['id'],
          'first_name': student['first_name'],
          'last_name': student['last_name'],
          'email': student['email'],
          'university': student['university'],
          'profile_picture_url': student['profile_picture_url'],
          'course_name':
              student['course'] != null ? student['course']['name'] : null,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting students for chat: $e');
      return [];
    }
  }

  // Create a new conversation or get existing one with a student
  Future<String?> createOrGetConversation(
    String alumniId,
    String studentId,
  ) async {
    try {
      // Check if a conversation already exists between these users
      final alumniConversations = await _supabase
          .from('chat_participants')
          .select('conversation_id')
          .eq('user_id', alumniId);

      final alumniConversationIds =
          alumniConversations
              .map((item) => item['conversation_id'] as String)
              .toList();

      if (alumniConversationIds.isNotEmpty) {
        final studentParticipants = await _supabase
            .from('chat_participants')
            .select('conversation_id')
            .eq('user_id', studentId)
            .inFilter('conversation_id', alumniConversationIds);

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

      // Add alumni as participant
      await _supabase.from('chat_participants').insert({
        'conversation_id': conversationId,
        'user_id': alumniId,
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
