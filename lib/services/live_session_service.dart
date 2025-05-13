import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/models/live_session_model.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

final liveSessionServiceProvider = Provider<LiveSessionService>((ref) {
  return LiveSessionService();
});

class LiveSessionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _agoraAppId =
      '182923c551cb4d8884532d1e17a293a9'; // Replace with your Agora App ID
  final String _tokenServerUrl =
      'https://agora-live.onrender.com/generate-token'; // Replace with your token server URL

  String get agoraAppId => _agoraAppId;

  // Create a new live session
  Future<LiveSession?> createLiveSession({
    required String creatorId,
    required String courseId,
    required String title,
  }) async {
    try {
      // Generate a unique channel name
      final channelName =
          '${creatorId}_${DateTime.now().millisecondsSinceEpoch}';

      final response =
          await _supabase
              .from('live_sessions')
              .insert({
                'creator_id': creatorId,
                'course_id': courseId,
                'title': title,
                'status': 'active',
                'channel_name': channelName,
              })
              .select()
              .single();

      return LiveSession.fromJson(response);
    } catch (e) {
      debugPrint('Error creating live session: $e');
      return null;
    }
  }

  // Schedule a new live session
  Future<LiveSession?> scheduleLiveSession({
    required String creatorId,
    required String courseId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    try {
      // Generate a unique channel name
      final channelName =
          '${creatorId}_${DateTime.now().millisecondsSinceEpoch}';

      final response =
          await _supabase
              .from('live_sessions')
              .insert({
                'creator_id': creatorId,
                'course_id': courseId,
                'title': title,
                'status': 'scheduled',
                'channel_name': channelName,
                'scheduled_at': scheduledAt.toIso8601String(),
                'started_at':
                    scheduledAt
                        .toIso8601String(), // Use scheduled time as default start time
              })
              .select()
              .single();

      return LiveSession.fromJson(response);
    } catch (e) {
      debugPrint('Error scheduling live session: $e');
      return null;
    }
  }

  // Reschedule a live session
  Future<LiveSession?> rescheduleLiveSession({
    required String sessionId,
    required DateTime newScheduledAt,
  }) async {
    try {
      final response =
          await _supabase
              .from('live_sessions')
              .update({
                'scheduled_at': newScheduledAt.toIso8601String(),
                'started_at':
                    newScheduledAt
                        .toIso8601String(), // Update start time as well
              })
              .eq('id', sessionId)
              .eq(
                'status',
                'scheduled',
              ) // Only allow rescheduling of scheduled sessions
              .select()
              .single();

      return LiveSession.fromJson(response);
    } catch (e) {
      debugPrint('Error rescheduling live session: $e');
      return null;
    }
  }

  // Cancel a scheduled live session
  Future<bool> cancelLiveSession(String sessionId) async {
    try {
      await _supabase
          .from('live_sessions')
          .update({'status': 'cancelled'})
          .eq('id', sessionId)
          .eq(
            'status',
            'scheduled',
          ); // Only scheduled sessions can be cancelled

      return true;
    } catch (e) {
      debugPrint('Error cancelling live session: $e');
      return false;
    }
  }

  // Start a scheduled live session
  Future<LiveSession?> startScheduledLiveSession(String sessionId) async {
    try {
      final response =
          await _supabase
              .from('live_sessions')
              .update({
                'status': 'active',
                'started_at': DateTime.now().toIso8601String(),
              })
              .eq('id', sessionId)
              .eq(
                'status',
                'scheduled',
              ) // Only scheduled sessions can be started
              .select()
              .single();

      return LiveSession.fromJson(response);
    } catch (e) {
      debugPrint('Error starting scheduled live session: $e');
      return null;
    }
  }

  // End a live session
  Future<bool> endLiveSession(String sessionId) async {
    try {
      await _supabase
          .from('live_sessions')
          .update({
            'status': 'ended',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      return true;
    } catch (e) {
      debugPrint('Error ending live session: $e');
      return false;
    }
  }

  // Get scheduled live sessions for a creator
  Future<List<LiveSession>> getScheduledLiveSessionsForCreator(
    String creatorId,
  ) async {
    try {
      final response = await _supabase
          .from('live_sessions')
          .select()
          .eq('creator_id', creatorId)
          .eq('status', 'scheduled')
          .order('scheduled_at', ascending: true);

      return response
          .map<LiveSession>((json) => LiveSession.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting scheduled live sessions: $e');
      return [];
    }
  }

  // Get active live sessions for a creator
  Future<List<LiveSession>> getActiveLiveSessionsForCreator(
    String creatorId,
  ) async {
    try {
      final response = await _supabase
          .from('live_sessions')
          .select()
          .eq('creator_id', creatorId)
          .eq('status', 'active');

      return response
          .map<LiveSession>((json) => LiveSession.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting active live sessions: $e');
      return [];
    }
  }

  // Get all live sessions for a creator
  Future<List<LiveSession>> getAllLiveSessionsForCreator(
    String creatorId,
  ) async {
    try {
      final response = await _supabase
          .from('live_sessions')
          .select()
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false);

      return response
          .map<LiveSession>((json) => LiveSession.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting all live sessions: $e');
      return [];
    }
  }

  // Get approved courses for a creator
  Future<List<Map<String, dynamic>>> getApprovedCoursesForCreator(
    String creatorId,
  ) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('creator_id', creatorId)
          .eq('is_approved', true)
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting approved courses: $e');
      return [];
    }
  }

  // Generate Agora token using Python server
  Future<String?> generateAgoraToken(String channelName, int uid) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'channelName': channelName,
          'uid': uid,
          'role': 1, // Publisher role
          'expirationTimeInSeconds': 3600, // 1 hour
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate token: ${response.body}');
      }

      final data = jsonDecode(response.body);
      return data['token'];
    } catch (e) {
      debugPrint('Error generating Agora token: $e');
      return null;
    }
  }
}
