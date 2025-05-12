import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/services/alumni_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';

final alumniServiceProvider = Provider<AlumniService>((ref) => AlumniService());

class AlumniDashboardTab extends ConsumerStatefulWidget {
  const AlumniDashboardTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AlumniDashboardTab> createState() => _AlumniDashboardTabState();
}

class _AlumniDashboardTabState extends ConsumerState<AlumniDashboardTab> {
  AlumniUser? _alumniUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlumniProfile();
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
      }
    } catch (e) {
      debugPrint('Error loading alumni profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_alumniUser == null) {
      return const Center(child: Text('Error loading alumni profile'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildApprovalStatus(),
          const SizedBox(height: 24),
          if (_alumniUser!.isApproved) _buildChatSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_alumniUser == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ProfilePictureWidget(
            userId: _alumniUser!.id,
            name: '${_alumniUser!.firstName} ${_alumniUser!.lastName ?? ''}',
            profilePictureUrl: _alumniUser!.profilePictureUrl ?? '',
            userType: UserType.alumni,
            size: 60,
            onPictureUpdated: (url) {
              setState(() {
                _alumniUser = _alumniUser!.copyWith(profilePictureUrl: url);
              });
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_alumniUser!.firstName} ${_alumniUser!.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _alumniUser!.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (_alumniUser!.university != null &&
                    _alumniUser!.university!.isNotEmpty)
                  Text(
                    _alumniUser!.university!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalStatus() {
    final isApproved = _alumniUser!.isApproved;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Status', style: AppTheme.subheadingStyle),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isApproved
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isApproved ? 'Approved' : 'Pending Approval',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isApproved
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isApproved
                  ? 'Your account has been approved. You have full access to all alumni features.'
                  : 'Your account is pending approval by an administrator. Some features may be limited until your account is approved.',
              style: const TextStyle(color: AppTheme.textLightColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Chat', style: AppTheme.subheadingStyle),
            const SizedBox(height: 16),
            const Text(
              'Connect with students through our chat system. You can view all students, start conversations, and manage your existing chats.',
              style: TextStyle(color: AppTheme.textLightColor),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildChatActionCard(
                    icon: Icons.people,
                    title: 'View Students',
                    description: 'Browse and chat with students',
                    onTap: () {
                      GoRouter.of(context).go('/alumni/students');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildChatActionCard(
                    icon: Icons.chat,
                    title: 'My Conversations',
                    description: 'View your ongoing conversations',
                    onTap: () {
                      GoRouter.of(context).go('/alumni/conversations');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textLightColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
