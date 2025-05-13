import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/admin_model.dart';
import 'package:admin_panel/services/admin_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:go_router/go_router.dart';

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
  List<Map<String, dynamic>> _statistics = [];
  List<Map<String, dynamic>> _courses = [];
  Map<String, dynamic> _studentStats = {
    'totalStudents': 0,
    'proStudents': 0,
    'freeStudents': 0,
    'proPercentage': '0',
  };

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
    _loadPendingApprovals();
    _loadStatistics();
    _loadCourses();
    _loadStudentStatistics();
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
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final adminService = ref.read(adminServiceProvider);

      final allAlumni = await adminService.getAllAlumni();
      final allCompanies = await adminService.getAllCompanies();
      final allContentCreators = await adminService.getAllContentCreators();

      final totalPendingApprovals =
          _pendingAlumni.length +
          _pendingCompanies.length +
          _pendingContentCreators.length;

      setState(() {
        _statistics = [
          {
            'title': 'Total Alumni',
            'value': allAlumni.length.toString(),
            'icon': Icons.school,
            'color': AppTheme.primaryColor,
          },
          {
            'title': 'Total Companies',
            'value': allCompanies.length.toString(),
            'icon': Icons.business,
            'color': AppTheme.infoColor,
          },
          {
            'title': 'Content Creators',
            'value': allContentCreators.length.toString(),
            'icon': Icons.create,
            'color': AppTheme.warningColor,
          },
          {
            'title': 'Pending Approvals',
            'value': totalPendingApprovals.toString(),
            'icon': Icons.pending_actions,
            'color': Colors.orange,
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> _loadCourses() async {
    try {
      final adminService = ref.read(adminServiceProvider);
      final courses = await adminService.getAllCourses();

      setState(() {
        _courses = courses;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
    }
  }

  Future<void> _loadStudentStatistics() async {
    try {
      final adminService = ref.read(adminServiceProvider);
      final studentStats = await adminService.getStudentStatistics();

      setState(() {
        _studentStats = studentStats;
      });
    } catch (e) {
      debugPrint('Error loading student statistics: $e');
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
        _loadStatistics();
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
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildStatisticsGrid(),
          const SizedBox(height: 24),
          _buildPendingApprovalsSection(),
          const SizedBox(height: 24),
          _buildCoursesSection(),
          const SizedBox(height: 24),
          _buildStudentStatisticsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    if (_adminUser == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          ProfilePictureWidget(
            userId: _adminUser!.id,
            name: '${_adminUser!.firstName} ${_adminUser!.lastName}',
            profilePictureUrl: _adminUser!.profilePictureUrl ?? '',
            userType: UserType.admin,
            size: 70,
            onPictureUpdated: (url) {
              setState(() {
                _adminUser = _adminUser!.copyWith(profilePictureUrl: url);
              });
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome,',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${_adminUser!.firstName} ${_adminUser!.lastName ?? ''}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _adminUser!.isSuperAdmin ? 'Super Admin' : 'Admin',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _adminUser!.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: _statistics.length,
      itemBuilder: (context, index) {
        final stat = _statistics[index];
        return _buildStatCard(
          title: stat['title'],
          value: stat['value'],
          icon: stat['icon'],
          color: stat['color'],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLightColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pending Approvals', style: AppTheme.subheadingStyle),
              const SizedBox(height: 24),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No pending approvals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All user accounts have been reviewed',
                        style: TextStyle(color: AppTheme.textLightColor),
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Approvals',
                  style: AppTheme.subheadingStyle,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total: $totalPending',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (_pendingAlumni.isNotEmpty) ...[
              _buildPendingSection('Alumni', _pendingAlumni, 'alumni'),
              const SizedBox(height: 24),
            ],
            if (_pendingCompanies.isNotEmpty) ...[
              _buildPendingSection('Companies', _pendingCompanies, 'company'),
              const SizedBox(height: 24),
            ],
            if (_pendingContentCreators.isNotEmpty) ...[
              _buildPendingSection(
                'Content Creators',
                _pendingContentCreators,
                'content_creator',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingSection(
    String title,
    List<Map<String, dynamic>> users,
    String userType,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              userType == 'alumni'
                  ? Icons.school
                  : userType == 'company'
                  ? Icons.business
                  : Icons.create,
              size: 18,
              color: AppTheme.textColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${users.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...users.map((user) => _buildPendingUserCard(user, userType)).toList(),
      ],
    );
  }

  Widget _buildPendingUserCard(Map<String, dynamic> user, String userType) {
    final String userId = user['id'];
    String displayName = '';

    if (userType == 'alumni' || userType == 'content_creator') {
      displayName = '${user['first_name']} ${user['last_name']}';
    } else if (userType == 'company') {
      displayName = user['company_name'];
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
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
  }

  Widget _buildCoursesSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Course Statistics',
                  style: AppTheme.subheadingStyle,
                ),
                Text(
                  'Total: ${_courses.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                _buildCourseStatColumn(
                  'Total Courses',
                  _courses.length.toString(),
                  Icons.book,
                  AppTheme.primaryColor,
                ),
                const SizedBox(width: 16),
                _buildCourseStatColumn(
                  'Approved',
                  _courses
                      .where((c) => c['is_approved'] == true)
                      .length
                      .toString(),
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
                const SizedBox(width: 16),
                _buildCourseStatColumn(
                  'Pending',
                  _courses
                      .where(
                        (c) =>
                            c['is_approved'] == null ||
                            c['is_approved'] == false,
                      )
                      .length
                      .toString(),
                  Icons.pending,
                  AppTheme.warningColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_courses.isNotEmpty && _courses.length > 5) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppTheme.infoColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'There are ${_courses.where((c) => c['is_approved'] == null || c['is_approved'] == false).length} courses pending review.',
                        style: const TextStyle(
                          color: AppTheme.infoColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  CustomButton(
                    text: 'Manage Categories',
                    onPressed: () {
                      // Navigate to categories management
                      GoRouter.of(context).go('/admin/categories');
                    },
                    icon: Icons.category,
                    type: ButtonType.primary,
                    height: 40,
                  ),
                  CustomButton(
                    text: 'Manage Gift Cards',
                    onPressed: () {
                      // Navigate to gift cards management
                      GoRouter.of(context).go('/admin/gift-cards');
                    },
                    icon: Icons.card_giftcard,
                    type: ButtonType.secondary,
                    height: 40,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseStatColumn(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentStatisticsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Student Statistics',
                  style: AppTheme.subheadingStyle,
                ),
                Text(
                  'Total: ${_studentStats['totalStudents']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                _buildStudentStatColumn(
                  'Total Students',
                  _studentStats['totalStudents'].toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
                const SizedBox(width: 16),
                _buildStudentStatColumn(
                  'Premium Users',
                  _studentStats['proStudents'].toString(),
                  Icons.workspace_premium,
                  Colors.amber,
                ),
                const SizedBox(width: 16),
                _buildStudentStatColumn(
                  'Free Users',
                  _studentStats['freeStudents'].toString(),
                  Icons.person_outline,
                  Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: double.parse(_studentStats['proPercentage']) / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${_studentStats['proPercentage']}% of students have Premium membership',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentStatColumn(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
