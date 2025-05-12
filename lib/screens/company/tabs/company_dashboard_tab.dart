import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/services/company_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';

final companyServiceProvider = Provider<CompanyService>(
  (ref) => CompanyService(),
);

class CompanyDashboardTab extends ConsumerStatefulWidget {
  const CompanyDashboardTab({Key? key}) : super(key: key);

  @override
  ConsumerState<CompanyDashboardTab> createState() =>
      _CompanyDashboardTabState();
}

class _CompanyDashboardTabState extends ConsumerState<CompanyDashboardTab> {
  CompanyUser? _companyUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _statistics = [];

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  Future<void> _loadCompanyProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the auth service from the provider
      final userProfile = await ref.read(authServiceProvider).getUserProfile();

      if (userProfile is CompanyUser) {
        setState(() {
          _companyUser = userProfile;
        });
        await _loadStatistics();
      }
    } catch (e) {
      debugPrint('Error loading company profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    if (_companyUser == null) return;

    try {
      // In a real app, you would use a method from the service
      // For now, we'll use mock data
      setState(() {
        _statistics = [
          {
            'title': 'Job Postings',
            'value': '12',
            'icon': Icons.work,
            'color': Colors.blue,
          },
          {
            'title': 'Applications',
            'value': '48',
            'icon': Icons.person_search,
            'color': Colors.green,
          },
          {
            'title': 'Interviews',
            'value': '8',
            'icon': Icons.people,
            'color': Colors.orange,
          },
          {
            'title': 'Hires',
            'value': '3',
            'icon': Icons.check_circle,
            'color': Colors.purple,
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_companyUser == null) {
      return const Center(child: Text('Error loading company profile'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildStatisticsGrid(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    if (_companyUser == null) return const SizedBox.shrink();

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
            userId: _companyUser!.id,
            name: _companyUser!.companyName,
            profilePictureUrl: _companyUser!.profilePictureUrl ?? '',
            userType: UserType.company,
            size: 60,
            onPictureUpdated: (url) {
              setState(() {
                _companyUser = _companyUser!.copyWith(profilePictureUrl: url);
              });
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _companyUser!.companyName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _companyUser!.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                // Display company type or other info if available
                Text(
                  'Company',
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textLightColor,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activity', style: AppTheme.subheadingStyle),
            const SizedBox(height: 16),
            _buildActivityItem(
              title: 'New Application',
              description: 'John Doe applied for Software Engineer position',
              time: '2 hours ago',
              icon: Icons.person_add,
              color: Colors.blue,
            ),
            const Divider(),
            _buildActivityItem(
              title: 'Interview Scheduled',
              description: 'Interview with Jane Smith for UX Designer position',
              time: '1 day ago',
              icon: Icons.event,
              color: Colors.orange,
            ),
            const Divider(),
            _buildActivityItem(
              title: 'Job Posting Updated',
              description: 'Marketing Manager position requirements updated',
              time: '3 days ago',
              icon: Icons.edit,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String description,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textLightColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
