import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/chat_conversation_model.dart';
import 'package:admin_panel/models/chat_message_model.dart';
import 'package:admin_panel/models/chat_participant_model.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/models/student_profile_model.dart';
import 'dart:async';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all conversations for the specified alumni user or current user
  Future<List<Map<String, dynamic>>> getConversations([String? userId]) async {
    try {
      // Get the current user ID
      final currentUserId = userId ?? _supabase.auth.currentUser!.id;
      if (currentUserId.isEmpty) {
        debugPrint('Error: Empty user ID when getting conversations');
        return [];
      }

      // Get conversations where the current user is a participant
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
          if (convId == null || convId.toString().isEmpty) {
            debugPrint('Skipping null or empty conversation ID');
            continue;
          }

          // Get conversation - skip if it doesn't exist
          final convDataResponse =
              await _supabase
                  .from('chat_conversations')
                  .select()
                  .eq('id', convId)
                  .maybeSingle();

          if (convDataResponse == null) {
            debugPrint('Conversation $convId not found, skipping');
            continue;
          }

          final convData = convDataResponse;

          // Get the other participant (student) - skip if there's no other participant
          final participantData =
              await _supabase
                  .from('chat_participants')
                  .select()
                  .eq('conversation_id', convId)
                  .neq('user_id', currentUserId)
                  .maybeSingle();

          if (participantData == null) {
            debugPrint(
              'No other participant found for conversation $convId, skipping',
            );
            continue;
          }

          final studentId = participantData['user_id'];
          if (studentId == null || studentId.toString().isEmpty) {
            debugPrint('Invalid student ID for conversation $convId, skipping');
            continue;
          }

          // Get student profile - skip if student profile doesn't exist
          final studentData =
              await _supabase
                  .from('user_students')
                  .select()
                  .eq('id', studentId)
                  .maybeSingle();

          if (studentData == null) {
            debugPrint(
              'Student profile not found for ID $studentId, skipping conversation',
            );
            continue;
          }

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

      // Sort by last message time, with safer parsing logic
      result.sort((a, b) {
        DateTime? aTime;
        DateTime? bTime;

        try {
          final aTimeStr = a['last_message_time'] ?? a['updated_at'];
          if (aTimeStr != null) aTime = DateTime.parse(aTimeStr);
        } catch (e) {
          // Ignore parsing errors
        }

        try {
          final bTimeStr = b['last_message_time'] ?? b['updated_at'];
          if (bTimeStr != null) bTime = DateTime.parse(bTimeStr);
        } catch (e) {
          // Ignore parsing errors
        }

        // Handle null cases
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1; // Move items with null time to the end
        if (bTime == null) return -1;

        return bTime.compareTo(aTime); // Latest first
      });

      return result;
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      rethrow; // Rethrow to allow proper handling by the caller
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
      // Validate inputs
      if (alumniId.isEmpty || studentId.isEmpty) {
        debugPrint('Error: Empty user IDs when creating conversation');
        return null;
      }

      // Check if users exist before creating a conversation
      final alumniExists = await _userExists(alumniId, 'user_alumni');
      final studentExists = await _userExists(studentId, 'user_students');

      if (!alumniExists || !studentExists) {
        debugPrint(
          'Error: Cannot create conversation - one or both users do not exist',
        );
        return null;
      }

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

      // Create a new conversation only if explicitly required
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
          .order('created_at', ascending: true);

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

      // Validate inputs
      if (userId.isEmpty || studentId.isEmpty) {
        debugPrint(
          'Error: Empty user ID when creating conversation with student',
        );
        return null;
      }

      // Check if users exist before creating a conversation
      final userExists = await _userExists(userId, 'user_alumni');
      final studentExists = await _userExists(studentId, 'user_students');

      if (!userExists || !studentExists) {
        debugPrint(
          'Error: Cannot create conversation - one or both users do not exist',
        );
        return null;
      }

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

      // Check if there are any unread messages first to avoid unnecessary updates
      final unreadMessages = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('is_read', false)
          .neq('sender_id', userId);

      // If no unread messages, return early
      if (unreadMessages.isEmpty) {
        return true;
      }

      // Add a timeout to prevent hanging requests
      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .timeout(const Duration(seconds: 5));

      return true;
    } catch (e) {
      // Log but don't rethrow - this is a background operation that can fail silently
      debugPrint('Error marking messages as read: $e');

      // If it's a timeout or server error, we should still consider it handled
      if (e.toString().contains('timeout') ||
          e.toString().contains('503') ||
          e.toString().contains('Service Unavailable')) {
        debugPrint(
          'Timeout or server error when marking messages as read - will retry later',
        );
      }

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
    try {
      // Create a controller to manage the stream
      final controller = StreamController<List<ChatMessage>>();

      // Add initial empty list to prevent waiting for first message
      controller.add([]);

      // Initial load of messages
      getMessages(conversationId)
          .then((messages) {
            if (!controller.isClosed) {
              controller.add(messages);

              // Mark messages as read on initial load if there are any unread
              _checkAndMarkMessagesAsRead(conversationId, messages);
            }
          })
          .catchError((error) {
            debugPrint('Error loading initial messages: $error');
            if (!controller.isClosed) {
              // Don't emit error, just keep the stream alive
              controller.add([]);
            }
          });

      // Set up the real-time subscription
      final subscription = _supabase
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .listen(
            (data) async {
              try {
                // Full message data needs to be loaded to include sender profiles
                final messages = await getMessages(conversationId);
                if (!controller.isClosed) {
                  controller.add(messages);

                  // Check for unread messages from others and mark as read if needed
                  _checkAndMarkMessagesAsRead(conversationId, messages);
                }
              } catch (e) {
                debugPrint('Error processing subscription update: $e');
                // Don't emit error, just keep using the last known messages
              }
            },
            onError: (error) {
              debugPrint('Error in subscription: $error');
              // Don't close the stream on error
            },
          );

      // Clean up when the stream is canceled
      controller.onCancel = () {
        subscription.cancel();
        controller.close();
      };

      return controller.stream;
    } catch (e) {
      debugPrint('Error setting up message stream: $e');
      // Return a stream that emits an empty list on error
      return Stream.value([]);
    }
  }

  // Helper method to check for unread messages and mark them as read
  void _checkAndMarkMessagesAsRead(
    String conversationId,
    List<ChatMessage> messages,
  ) {
    try {
      final currentUserId = _supabase.auth.currentUser!.id;
      final hasUnreadFromOthers = messages.any(
        (msg) => msg.senderId != currentUserId && !msg.isRead,
      );

      // Only attempt to mark messages as read if there are any unread from others
      if (hasUnreadFromOthers) {
        markMessagesAsRead(conversationId);
      }
    } catch (e) {
      debugPrint('Error in _checkAndMarkMessagesAsRead: $e');
    }
  }

  // Helper to check if a user exists in a specific table
  Future<bool> _userExists(String userId, String tableName) async {
    try {
      final result =
          await _supabase
              .from(tableName)
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }
}
