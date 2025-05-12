import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/admin_model.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

class AdminDashboardTab extends ConsumerStatefulWidget {
  const AdminDashboardTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends ConsumerState<AdminDashboardTab> {
  AdminUser? _adminUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingAlumni = [];
  List<Map<String, dynamic>> _pendingCompanies = [];
  List<Map<String, dynamic>> _pendingContentCreators = [];

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
    _loadPendingApprovals();
  }

  Future<void> _loadAdminProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the auth service from the provider
      final userProfile = await ref.read(authServiceProvider).getUserProfile();

      if (userProfile is AdminUser) {
        setState(() {
          _adminUser = userProfile;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingApprovals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);

      final pendingAlumni = await adminService.getPendingAlumni();
      final pendingCompanies = await adminService.getPendingCompanies();
      final pendingContentCreators =
          await adminService.getPendingContentCreators();

      setState(() {
        _pendingAlumni = pendingAlumni.map((user) => user.toJson()).toList();
        _pendingCompanies =
            pendingCompanies.map((user) => user.toJson()).toList();
        _pendingContentCreators =
            pendingContentCreators.map((user) => user.toJson()).toList();
      });
    } catch (e) {
      debugPrint('Error loading pending approvals: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveUser(String userType, String userId) async {
    try {
      final adminService = ref.read(adminServiceProvider);
      bool success = false;

      switch (userType) {
        case 'alumni':
          success = await adminService.approveAlumni(userId);
          break;
        case 'company':
          success = await adminService.approveCompany(userId);
          break;
        case 'content_creator':
          success = await adminService.approveContentCreator(userId);
          break;
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadPendingApprovals();
      }
    } catch (e) {
      debugPrint('Error approving user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve user'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_adminUser == null) {
      return const Center(child: Text('Error loading admin profile'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildPendingApprovalsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_adminUser == null) return const SizedBox.shrink();

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
            userId: _adminUser!.id,
            name: '${_adminUser!.firstName} ${_adminUser!.lastName}',
            profilePictureUrl: _adminUser!.profilePictureUrl,
            userType: UserType.admin,
            size: 60,
            onPictureUpdated: (url) {
              setState(() {
                _adminUser = _adminUser!.copyWith(profilePictureUrl: url);
              });
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_adminUser!.firstName} ${_adminUser!.lastName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _adminUser!.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  _adminUser!.isSuperAdmin ? 'Super Admin' : 'Admin',
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

  Widget _buildPendingApprovalsSection() {
    final totalPending =
        _pendingAlumni.length +
        _pendingCompanies.length +
        _pendingContentCreators.length;

    if (totalPending == 0) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No pending approvals',
              style: TextStyle(fontSize: 16, color: AppTheme.textLightColor),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pending Approvals', style: AppTheme.subheadingStyle),
            const SizedBox(height: 16),
            if (_pendingAlumni.isNotEmpty) ...[
              const Text(
                'Alumni',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildPendingUsersList(_pendingAlumni, 'alumni'),
              const SizedBox(height: 16),
            ],
            if (_pendingCompanies.isNotEmpty) ...[
              const Text(
                'Companies',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildPendingUsersList(_pendingCompanies, 'company'),
              const SizedBox(height: 16),
            ],
            if (_pendingContentCreators.isNotEmpty) ...[
              const Text(
                'Content Creators',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildPendingUsersList(
                _pendingContentCreators,
                'content_creator',
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPendingUsersList(
    List<Map<String, dynamic>> users,
    String userType,
  ) {
    return users.map((user) {
      final String userId = user['id'];
      String displayName = '';

      if (userType == 'alumni' || userType == 'content_creator') {
        displayName = '${user['first_name']} ${user['last_name']}';
      } else if (userType == 'company') {
        displayName = user['company_name'];
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'],
                      style: const TextStyle(color: AppTheme.textLightColor),
                    ),
                  ],
                ),
              ),
              CustomButton(
                text: 'Approve',
                onPressed: () => _approveUser(userType, userId),
                type: ButtonType.success,
                height: 40,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
