import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/admin_model.dart';
import 'package:admin_panel/models/course_category_model.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/services/course_category_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:admin_panel/services/auth_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final courseCategoryServiceProvider = Provider<CourseCategoryService>((ref) {
  return CourseCategoryService();
});

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AdminUser? _adminUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _signOut() async {
    try {
      // Use the auth notifier to sign out
      await ref.read(authProvider.notifier).signOut();

      if (mounted) {
        GoRouter.of(context).go('/login');
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Approvals', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Content', icon: Icon(Icons.content_paste)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _adminUser == null
              ? const Center(child: Text('Error loading admin profile'))
              : Column(
                children: [
                  _buildProfileHeader(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPendingApprovalsTab(),
                        _buildUsersTab(),
                        _buildContentTab(),
                      ],
                    ),
                  ),
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

  Widget _buildPendingApprovalsTab() {
    return const PendingApprovalsTab();
  }

  Widget _buildUsersTab() {
    return const UsersTab();
  }

  Widget _buildContentTab() {
    return const ContentTab();
  }
}

class PendingApprovalsTab extends ConsumerStatefulWidget {
  const PendingApprovalsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<PendingApprovalsTab> createState() =>
      _PendingApprovalsTabState();
}

class _PendingApprovalsTabState extends ConsumerState<PendingApprovalsTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingAlumni = [];
  List<Map<String, dynamic>> _pendingCompanies = [];
  List<Map<String, dynamic>> _pendingContentCreators = [];

  @override
  void initState() {
    super.initState();
    _loadPendingApprovals();
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

    final totalPending =
        _pendingAlumni.length +
        _pendingCompanies.length +
        _pendingContentCreators.length;

    if (totalPending == 0) {
      return const Center(
        child: Text(
          'No pending approvals',
          style: TextStyle(fontSize: 18, color: AppTheme.textLightColor),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pendingAlumni.isNotEmpty) ...[
            const Text('Pending Alumni', style: AppTheme.subheadingStyle),
            const SizedBox(height: 8),
            ..._buildPendingUsersList(_pendingAlumni, 'alumni'),
            const SizedBox(height: 24),
          ],

          if (_pendingCompanies.isNotEmpty) ...[
            const Text('Pending Companies', style: AppTheme.subheadingStyle),
            const SizedBox(height: 8),
            ..._buildPendingUsersList(_pendingCompanies, 'company'),
            const SizedBox(height: 24),
          ],

          if (_pendingContentCreators.isNotEmpty) ...[
            const Text(
              'Pending Content Creators',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 8),
            ..._buildPendingUsersList(
              _pendingContentCreators,
              'content_creator',
            ),
          ],
        ],
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

class UsersTab extends ConsumerStatefulWidget {
  const UsersTab({Key? key}) : super(key: key);

  @override
  ConsumerState<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<UsersTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _alumni = [];
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _contentCreators = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);

      final admins = await adminService.getAllAdmins();
      final alumni = await adminService.getAllAlumni();
      final companies = await adminService.getAllCompanies();
      final contentCreators = await adminService.getAllContentCreators();

      setState(() {
        _admins = admins.map((user) => user.toJson()).toList();
        _alumni = alumni.map((user) => user.toJson()).toList();
        _companies = companies.map((user) => user.toJson()).toList();
        _contentCreators =
            contentCreators.map((user) => user.toJson()).toList();
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
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

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Admins'),
              Tab(text: 'Alumni'),
              Tab(text: 'Companies'),
              Tab(text: 'Content Creators'),
            ],
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textLightColor,
            indicatorColor: AppTheme.accentColor,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersList(_admins, 'admin'),
                _buildUsersList(_alumni, 'alumni'),
                _buildUsersList(_companies, 'company'),
                _buildUsersList(_contentCreators, 'content_creator'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users, String userType) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(fontSize: 18, color: AppTheme.textLightColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        String displayName = '';
        String subtitle = '';

        if (userType == 'admin') {
          displayName = '${user['first_name']} ${user['last_name'] ?? ''}';
          subtitle = user['username'];
        } else if (userType == 'alumni' || userType == 'content_creator') {
          displayName = '${user['first_name']} ${user['last_name']}';
          subtitle = user['email'];
        } else if (userType == 'company') {
          displayName = user['company_name'];
          subtitle = user['email'];
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing:
                userType == 'admin' && user['is_super_admin'] == true
                    ? const Chip(
                      label: Text('Super Admin'),
                      backgroundColor: AppTheme.accentColor,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    )
                    : user['is_approved'] == true
                    ? const Chip(
                      label: Text('Approved'),
                      backgroundColor: AppTheme.successColor,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    )
                    : const Chip(
                      label: Text('Pending'),
                      backgroundColor: AppTheme.warningColor,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                    ),
          ),
        );
      },
    );
  }
}

class ContentTab extends ConsumerStatefulWidget {
  const ContentTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends ConsumerState<ContentTab> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return const CourseManagementTab();
  }
}

class CourseManagementTab extends ConsumerStatefulWidget {
  const CourseManagementTab({Key? key}) : super(key: key);

  @override
  ConsumerState<CourseManagementTab> createState() =>
      _CourseManagementTabState();
}

class _CourseManagementTabState extends ConsumerState<CourseManagementTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final courses = await adminService.getAllCourses();

      setState(() {
        _courses = courses;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Courses', style: AppTheme.subheadingStyle),
              const SizedBox(height: 16),
              if (_courses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No courses found.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textLightColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    final bool isActive = course['is_active'] ?? false;
                    final bool isApproved = course['is_approved'] ?? false;
                    final categoryData = course['course_categories'];
                    final String categoryName =
                        categoryData != null
                            ? categoryData['name'] ?? 'Uncategorized'
                            : 'Uncategorized';
                    final creatorData = course['creator'];
                    final String creatorName =
                        creatorData != null
                            ? '${creatorData['first_name']} ${creatorData['last_name']}'
                            : 'Unknown';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    course['title'] ?? 'Untitled Course',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        isApproved ? 'Approved' : 'Pending',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor:
                                          isApproved
                                              ? AppTheme.successColor
                                              : AppTheme.warningColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor:
                                          isActive
                                              ? AppTheme.accentColor
                                              : AppTheme.textLightColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              course['description'] ??
                                  'No description provided',
                              style: const TextStyle(color: AppTheme.textColor),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.category,
                                  size: 16,
                                  color: AppTheme.textLightColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Category: $categoryName',
                                  style: const TextStyle(
                                    color: AppTheme.textLightColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppTheme.textLightColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Creator: $creatorName',
                                  style: const TextStyle(
                                    color: AppTheme.textLightColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            if (!isApproved)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CustomButton(
                                      text: 'Approve',
                                      onPressed:
                                          () => _approveCourse(course['id']),
                                      type: ButtonType.success,
                                      height: 36,
                                    ),
                                    const SizedBox(width: 8),
                                    CustomButton(
                                      text: 'Reject',
                                      onPressed:
                                          () => _showRejectDialog(course['id']),
                                      type: ButtonType.danger,
                                      height: 36,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
  }

  Future<void> _approveCourse(String courseId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.approveCourse(courseId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course approved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadCourses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while approving course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRejectDialog(String courseId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Course'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please provide a reason for rejection:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter rejection reason',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _rejectCourse(courseId, reasonController.text);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
    ).then((_) => reasonController.dispose());
  }

  Future<void> _rejectCourse(String courseId, String reason) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final adminService = ref.read(adminServiceProvider);
      final success = await adminService.rejectCourse(courseId, reason);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course rejected successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadCourses();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting course: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while rejecting course'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
