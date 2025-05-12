import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/live_session_model.dart';
import 'package:admin_panel/services/live_session_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class LiveSessionsScreen extends ConsumerStatefulWidget {
  const LiveSessionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LiveSessionsScreen> createState() => _LiveSessionsScreenState();
}

class _LiveSessionsScreenState extends ConsumerState<LiveSessionsScreen> {
  bool _isLoading = true;
  List<LiveSession> _activeSessions = [];
  List<LiveSession> _pastSessions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLiveSessions();
  }

  Future<void> _loadLiveSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final liveSessionService = ref.read(liveSessionServiceProvider);

      // Get active sessions
      final activeSessions = await liveSessionService
          .getActiveLiveSessionsForCreator(user.id);

      // Get all sessions (including ended ones)
      final allSessions = await liveSessionService.getAllLiveSessionsForCreator(
        user.id,
      );

      // Filter out active sessions to get past sessions
      final pastSessions =
          allSessions.where((session) => session.status == 'ended').toList();

      setState(() {
        _activeSessions = activeSessions;
        _pastSessions = pastSessions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading live sessions: $e');
      setState(() {
        _errorMessage = 'Failed to load live sessions: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _endLiveSession(LiveSession session) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final liveSessionService = ref.read(liveSessionServiceProvider);
      final success = await liveSessionService.endLiveSession(session.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live session ended successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadLiveSessions();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to end live session'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error ending live session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEndConfirmation(LiveSession session) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('End Live Session'),
            content: const Text(
              'Are you sure you want to end this live session? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _endLiveSession(session);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('End Session'),
              ),
            ],
          ),
    );
  }

  void _continueLiveSession(LiveSession session) {
    GoRouter.of(context).push(
      '/content-creator/broadcast/${session.id}',
      extra: {'liveSession': session},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Live Sessions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Try Again',
                        onPressed: _loadLiveSessions,
                        type: ButtonType.primary,
                      ),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadLiveSessions,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active sessions section
                      const Text(
                        'Active Live Sessions',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 16),
                      if (_activeSessions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'You don\'t have any active live sessions.',
                            style: TextStyle(
                              color: AppTheme.textLightColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ..._activeSessions
                            .map(_buildActiveSessionCard)
                            .toList(),

                      const SizedBox(height: 32),

                      // Past sessions section
                      const Text(
                        'Past Live Sessions',
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 16),
                      if (_pastSessions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'You don\'t have any past live sessions.',
                            style: TextStyle(
                              color: AppTheme.textLightColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ..._pastSessions.map(_buildPastSessionCard).toList(),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouter.of(context).push('/content-creator/go-live');
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
        tooltip: 'Start New Live Session',
      ),
    );
  }

  Widget _buildActiveSessionCard(LiveSession session) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final startTime = dateFormat.format(session.startedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 12),
                      SizedBox(width: 8),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Started: $startTime',
                  style: const TextStyle(color: AppTheme.textLightColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.people,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Viewers: ${session.viewerCount}',
                  style: const TextStyle(color: AppTheme.textLightColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: 'Continue',
                  onPressed: () => _continueLiveSession(session),
                  type: ButtonType.primary,
                  height: 36,
                  icon: Icons.play_arrow,
                ),
                const SizedBox(width: 8),
                CustomButton(
                  text: 'End',
                  onPressed: () => _showEndConfirmation(session),
                  type: ButtonType.danger,
                  height: 36,
                  icon: Icons.stop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastSessionCard(LiveSession session) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final startTime = dateFormat.format(session.startedAt);
    final endTime =
        session.endedAt != null
            ? dateFormat.format(session.endedAt!)
            : 'Unknown';

    // Calculate duration if endedAt is available
    String duration = 'Unknown';
    if (session.endedAt != null) {
      final difference = session.endedAt!.difference(session.startedAt);
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      duration = '$hours hr ${minutes.toString().padLeft(2, '0')} min';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Date: $startTime',
                  style: const TextStyle(color: AppTheme.textLightColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.timer,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration: $duration',
                  style: const TextStyle(color: AppTheme.textLightColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.people,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Viewers: ${session.viewerCount}',
                  style: const TextStyle(color: AppTheme.textLightColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
