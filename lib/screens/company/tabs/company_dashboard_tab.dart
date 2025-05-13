import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/models/internship_model.dart';
import 'package:admin_panel/services/company_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:admin_panel/widgets/custom_button.dart';

final companyServiceProvider = Provider<CompanyService>(
  (ref) => CompanyService(),
);

class CompanyDashboardTab extends ConsumerStatefulWidget {
  final VoidCallback? onViewAllInternships;

  const CompanyDashboardTab({Key? key, this.onViewAllInternships})
    : super(key: key);

  @override
  ConsumerState<CompanyDashboardTab> createState() =>
      _CompanyDashboardTabState();
}

class _CompanyDashboardTabState extends ConsumerState<CompanyDashboardTab> {
  CompanyUser? _companyUser;
  bool _isLoading = true;
  List<Internship> _internships = [];
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
        await _loadInternships();
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
      final companyService = ref.read(companyServiceProvider);
      final internships = await companyService.getCompanyInternships(
        _companyUser!.id,
      );

      int activeInternships = 0;

      for (var internship in internships) {
        if (internship.isActive == true && internship.isApproved == true) {
          activeInternships++;
        }
      }

      setState(() {
        _statistics = [
          {
            'title': 'Active Internships',
            'value': activeInternships.toString(),
            'icon': Icons.work,
            'color': AppTheme.primaryColor,
          },
          {
            'title': 'Total Internships',
            'value': internships.length.toString(),
            'icon': Icons.business_center,
            'color': AppTheme.infoColor,
          },
        ];
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> _loadInternships() async {
    if (_companyUser == null) return;

    try {
      final companyService = ref.read(companyServiceProvider);
      final internships = await companyService.getCompanyInternships(
        _companyUser!.id,
      );

      setState(() {
        _internships = internships;
      });
    } catch (e) {
      debugPrint('Error loading internships: $e');
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
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          _buildStatisticsGrid(),
          const SizedBox(height: 24),
          _buildApprovalStatusCard(),
          const SizedBox(height: 24),
          _buildRecentInternships(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    if (_companyUser == null) return const SizedBox.shrink();

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
            userId: _companyUser!.id,
            name: _companyUser!.companyName,
            profilePictureUrl: _companyUser!.profilePictureUrl ?? '',
            userType: UserType.company,
            size: 70,
            onPictureUpdated: (url) {
              setState(() {
                _companyUser = _companyUser!.copyWith(profilePictureUrl: url);
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
                  _companyUser!.companyName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _companyUser!.email,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
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
            Icon(icon, color: color, size: 30),
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

  Widget _buildApprovalStatusCard() {
    final isApproved = _companyUser!.isApproved;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Status', style: AppTheme.subheadingStyle),
            const SizedBox(height: 20),
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
                  ? 'Your account has been approved. You can now post internships.'
                  : 'Your account is pending approval by an administrator. You cannot post internships until your account is approved.',
              style: const TextStyle(color: AppTheme.textLightColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentInternships() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Internships', style: AppTheme.subheadingStyle),
            if (_internships.isNotEmpty)
              TextButton(
                onPressed: widget.onViewAllInternships,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_companyUser!.isApproved)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Your account needs to be approved before you can post internships.',
              style: TextStyle(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (_internships.isEmpty && _companyUser!.isApproved)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(
                    Icons.work_off_outlined,
                    size: 64,
                    color: AppTheme.textLightColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No internships posted yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first internship to get started',
                    style: TextStyle(color: AppTheme.textLightColor),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Create Internship',
                    onPressed:
                        widget.onViewAllInternships != null
                            ? widget.onViewAllInternships!
                            : () {},
                    icon: Icons.add,
                    type: ButtonType.primary,
                  ),
                ],
              ),
            ),
          ),
        ..._internships.take(3).map(_buildInternshipCard).toList(),
        if (_internships.length > 3)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: widget.onViewAllInternships,
                icon: const Icon(Icons.visibility),
                label: const Text('View All Internships'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInternshipCard(Internship internship) {
    final bool isActive = internship.isActive;
    final bool isApproved = internship.isApproved ?? false;
    final List<String> skills = internship.skills;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    internship.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusIndicator(isApproved, isActive),
              ],
            ),
            const Divider(height: 24),
            Text(
              internship.description,
              style: const TextStyle(color: AppTheme.textColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    skills
                        .take(3)
                        .map((skill) => _buildSkillChip(skill))
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isApproved, bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isApproved ? 'Status: Approved' : 'Status: Pending',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isApproved ? AppTheme.successColor : AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isApproved ? AppTheme.successColor : AppTheme.warningColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive ? 'Availability: Active' : 'Availability: Inactive',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? AppTheme.infoColor : AppTheme.textLightColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppTheme.infoColor : AppTheme.textLightColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.primaryColor.withOpacity(0.8),
        ),
      ),
    );
  }
}
