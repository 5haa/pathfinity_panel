import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/student_profile_model.dart';
import 'package:admin_panel/services/student_service.dart';
import 'package:admin_panel/services/chat_service.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:admin_panel/services/auth_service.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  final String studentId;

  const StudentProfileScreen({Key? key, required this.studentId})
    : super(key: key);

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  StudentProfile? _student;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final studentService = ref.read(
        Provider<StudentService>((ref) => StudentService()),
      );
      final student = await studentService.getStudentProfile(widget.studentId);
      setState(() {
        _student = student;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading student profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startChat() async {
    if (_student == null) return;

    try {
      final chatService = ref.read(
        Provider<ChatService>((ref) => ChatService()),
      );
      final conversationId = await chatService.createConversationWithStudent(
        _student!.id,
      );

      if (conversationId != null && mounted) {
        // Extract the tab parameter from the current route
        final uri = GoRouterState.of(context).uri;
        final pathSegments = uri.pathSegments;
        final tab = pathSegments.length > 1 ? pathSegments[1] : 'students';

        // Navigate to chat screen with the correct path format and student name
        GoRouter.of(context).go(
          '/alumni/$tab/chat/$conversationId?studentName=${Uri.encodeComponent(_student!.fullName)}',
        );
      }
    } catch (e) {
      debugPrint('Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start chat. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textLightColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: AppTheme.textColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_student?.fullName ?? 'Student Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Extract the tab parameter from the current route
            final uri = GoRouterState.of(context).uri;
            final pathSegments = uri.pathSegments;
            final tab = pathSegments.length > 1 ? pathSegments[1] : 'students';

            // Navigate back to the appropriate tab
            GoRouter.of(context).go('/alumni/$tab');
          },
        ),
        actions: [
          if (_student != null)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: _startChat,
              tooltip: 'Start Chat',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _student == null
              ? const Center(child: Text('Student not found'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child:
                          _student!.profilePictureUrl != null &&
                                  _student!.profilePictureUrl!.isNotEmpty
                              ? ProfilePictureWidget(
                                userId: _student!.id,
                                name: _student!.fullName,
                                profilePictureUrl: _student!.profilePictureUrl,
                                userType: UserType.unknown,
                                size: 100,
                                isEditable: false,
                              )
                              : CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.primaryColor,
                                child: Text(
                                  _student!.firstName.isNotEmpty &&
                                          _student!.lastName.isNotEmpty
                                      ? _student!.firstName[0] +
                                          _student!.lastName[0]
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: AppTheme.headingStyle,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow('Name', _student!.fullName),
                            if (_student!.email != null)
                              _buildInfoRow('Email', _student!.email!),
                            if (_student!.birthdate != null)
                              _buildInfoRow(
                                'Birthdate',
                                '${_student!.birthdate!.day}/${_student!.birthdate!.month}/${_student!.birthdate!.year}',
                              ),
                            if (_student!.gender != null)
                              _buildInfoRow('Gender', _student!.gender!),
                            if (_student!.skills.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Skills',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textLightColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            _student!.skills
                                                .map(
                                                  (skill) => Chip(
                                                    label: Text(skill),
                                                    backgroundColor: AppTheme
                                                        .primaryColor
                                                        .withOpacity(0.1),
                                                    labelStyle: const TextStyle(
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Information',
                              style: AppTheme.headingStyle,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Premium Status',
                              _student!.premium ? 'Premium' : 'Standard',
                            ),
                            if (_student!.premium &&
                                _student!.premiumExpiresAt != null)
                              _buildInfoRow(
                                'Premium Expires',
                                '${_student!.premiumExpiresAt!.day}/${_student!.premiumExpiresAt!.month}/${_student!.premiumExpiresAt!.year}',
                              ),
                            _buildInfoRow(
                              'Member Since',
                              '${_student!.createdAt.day}/${_student!.createdAt.month}/${_student!.createdAt.year}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
