import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/services/alumni_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/services/chat_service.dart';

final alumniServiceProvider = Provider<AlumniService>((ref) => AlumniService());
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class AlumniChatTab extends ConsumerStatefulWidget {
  const AlumniChatTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AlumniChatTab> createState() => _AlumniChatTabState();
}

class _AlumniChatTabState extends ConsumerState<AlumniChatTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AlumniUser? _alumniUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlumniProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlumniProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the auth service from the provider
      final userProfile = await ref.read(authServiceProvider).getUserProfile();

      if (userProfile is AlumniUser) {
        setState(() {
          _alumniUser = userProfile;
        });
        await _loadStudents();
        await _loadConversations();
      }
    } catch (e) {
      debugPrint('Error loading alumni profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    if (_alumniUser == null) return;

    try {
      // In a real app, you would use a method from the service
      // For now, we'll use mock data
      setState(() {
        _students = [
          {
            'id': '1',
            'first_name': 'John',
            'last_name': 'Doe',
            'university': 'Example University',
            'profile_picture_url': '',
          },
          {
            'id': '2',
            'first_name': 'Jane',
            'last_name': 'Smith',
            'university': 'Sample College',
            'profile_picture_url': '',
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  Future<void> _loadConversations() async {
    if (_alumniUser == null) return;

    try {
      // In a real app, you would use a method from the service
      // For now, we'll use mock data
      setState(() {
        _conversations = [
          {
            'id': '1',
            'student': {
              'id': '1',
              'first_name': 'John',
              'last_name': 'Doe',
              'profile_picture_url': '',
            },
            'last_message': 'Hello, I have a question about the course.',
            'last_message_time':
                DateTime.now()
                    .subtract(const Duration(hours: 2))
                    .toIso8601String(),
            'unread': true,
          },
          {
            'id': '2',
            'student': {
              'id': '2',
              'first_name': 'Jane',
              'last_name': 'Smith',
              'profile_picture_url': '',
            },
            'last_message': 'Thanks for your help!',
            'last_message_time':
                DateTime.now()
                    .subtract(const Duration(days: 1))
                    .toIso8601String(),
            'unread': false,
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  void _viewStudentProfile(String studentId) {
    GoRouter.of(
      context,
    ).push('/alumni/student_profile', extra: {'id': studentId});
  }

  void _openChat(String conversationId, String studentName) {
    GoRouter.of(context).push(
      '/alumni/chat',
      extra: {'conversationId': conversationId, 'studentName': studentName},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_alumniUser == null) {
      return const Center(child: Text('Error loading alumni profile'));
    }

    if (!_alumniUser!.isApproved) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock, size: 64, color: AppTheme.warningColor),
              const SizedBox(height: 16),
              const Text(
                'Account Pending Approval',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warningColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your account is pending approval by an administrator. Chat features will be available once your account is approved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textLightColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Students'), Tab(text: 'Conversations')],
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textLightColor,
          indicatorColor: AppTheme.accentColor,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildStudentsTab(), _buildConversationsTab()],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab() {
    if (_students.isEmpty) {
      return const Center(
        child: Text(
          'No students found',
          style: TextStyle(fontSize: 16, color: AppTheme.textLightColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final String studentId = student['id'];
        final String firstName = student['first_name'] ?? '';
        final String lastName = student['last_name'] ?? '';
        final String displayName = '$firstName $lastName';
        final String? profilePictureUrl = student['profile_picture_url'];
        final String? university = student['university'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.secondaryColor,
              backgroundImage:
                  profilePictureUrl != null && profilePictureUrl.isNotEmpty
                      ? NetworkImage(profilePictureUrl)
                      : null,
              child:
                  profilePictureUrl == null || profilePictureUrl.isEmpty
                      ? Text(
                        displayName.isNotEmpty
                            ? displayName.substring(0, 1)
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            title: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle:
                university != null && university.isNotEmpty
                    ? Text(university)
                    : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.person),
                  tooltip: 'View Profile',
                  onPressed: () => _viewStudentProfile(studentId),
                ),
                IconButton(
                  icon: const Icon(Icons.chat),
                  tooltip: 'Start Chat',
                  onPressed: () {
                    // Start a new conversation or open existing one
                    // For simplicity, we'll just navigate to the student profile
                    _viewStudentProfile(studentId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationsTab() {
    if (_conversations.isEmpty) {
      return const Center(
        child: Text(
          'No conversations yet',
          style: TextStyle(fontSize: 16, color: AppTheme.textLightColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final String conversationId = conversation['id'];
        final Map<String, dynamic>? student = conversation['student'];

        if (student == null) {
          return const SizedBox.shrink();
        }

        final String firstName = student['first_name'] ?? '';
        final String lastName = student['last_name'] ?? '';
        final String displayName = '$firstName $lastName';
        final String? profilePictureUrl = student['profile_picture_url'];
        final String? lastMessage = conversation['last_message'];
        final DateTime? lastMessageTime =
            conversation['last_message_time'] != null
                ? DateTime.parse(conversation['last_message_time'])
                : null;
        final bool unread = conversation['unread'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: unread ? AppTheme.accentColor.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.secondaryColor,
              backgroundImage:
                  profilePictureUrl != null && profilePictureUrl.isNotEmpty
                      ? NetworkImage(profilePictureUrl)
                      : null,
              child:
                  profilePictureUrl == null || profilePictureUrl.isEmpty
                      ? Text(
                        displayName.isNotEmpty
                            ? displayName.substring(0, 1)
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
            title: Text(
              displayName,
              style: TextStyle(
                fontWeight: unread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle:
                lastMessage != null && lastMessage.isNotEmpty
                    ? Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                    : const Text('No messages yet'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessageTime != null)
                  Text(
                    _formatTime(lastMessageTime),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          unread
                              ? AppTheme.primaryColor
                              : AppTheme.textLightColor,
                    ),
                  ),
                const SizedBox(height: 4),
                if (unread)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '•',
                      style: TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
              ],
            ),
            onTap: () => _openChat(conversationId, displayName),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
