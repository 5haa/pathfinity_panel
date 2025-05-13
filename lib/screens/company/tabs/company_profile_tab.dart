import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/services/company_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:intl/intl.dart';

final companyServiceProvider = Provider<CompanyService>(
  (ref) => CompanyService(),
);

class CompanyProfileTab extends ConsumerStatefulWidget {
  const CompanyProfileTab({Key? key}) : super(key: key);

  @override
  ConsumerState<CompanyProfileTab> createState() => _CompanyProfileTabState();
}

class _CompanyProfileTabState extends ConsumerState<CompanyProfileTab> {
  CompanyUser? _companyUser;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _emailController = TextEditingController();
    _loadCompanyProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = await ref.read(authServiceProvider).getUserProfile();

      if (userProfile is CompanyUser) {
        setState(() {
          _companyUser = userProfile;
          _companyNameController.text = userProfile.companyName;
          _emailController.text = userProfile.email;
        });
      }
    } catch (e) {
      debugPrint('Error loading company profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final companyService = ref.read(companyServiceProvider);

      final success = await companyService.updateProfile(
        userId: _companyUser!.id,
        companyName: _companyNameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadCompanyProfile();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while updating profile'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

  Future<void> _initiatePasswordReset() async {
    try {
      if (_companyUser != null) {
        // Navigate to the forgot password screen with the email pre-filled
        GoRouter.of(context).go('/forgot-password');

        // Show a message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Follow the instructions to reset your password'),
              backgroundColor: AppTheme.infoColor,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initiating password reset: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
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
          _buildProfileCard(),
          const SizedBox(height: 24),
          _buildAccountDetailsCard(),
          const SizedBox(height: 24),
          _buildAccountActions(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Company Profile', style: AppTheme.headingStyle),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    tooltip: 'Edit Profile',
                  ),
              ],
            ),
            const Divider(height: 32),
            _isEditing ? _buildEditForm() : _buildProfileInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ProfilePictureWidget(
              userId: _companyUser!.id,
              name: _companyUser!.companyName,
              profilePictureUrl: _companyUser!.profilePictureUrl ?? '',
              userType: UserType.company,
              size: 120,
              onPictureUpdated: (url) {
                setState(() {
                  _companyUser = _companyUser!.copyWith(profilePictureUrl: url);
                });
              },
            ),
          ),
        ),
        _buildInfoRow('Company Name', _companyUser!.companyName),
        _buildInfoRow('Email', _companyUser!.email),
        _buildInfoRow(
          'Account Status',
          _companyUser!.isApproved ? 'Approved' : 'Pending Approval',
          icon: _companyUser!.isApproved ? Icons.check_circle : Icons.pending,
          iconColor:
              _companyUser!.isApproved
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: iconColor ?? AppTheme.textColor),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLightColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: iconColor ?? AppTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ProfilePictureWidget(
                userId: _companyUser!.id,
                name: _companyUser!.companyName,
                profilePictureUrl: _companyUser!.profilePictureUrl ?? '',
                userType: UserType.company,
                size: 120,
                onPictureUpdated: (url) {
                  setState(() {
                    _companyUser = _companyUser!.copyWith(
                      profilePictureUrl: url,
                    );
                  });
                },
              ),
            ),
          ),
          CustomTextField(
            label: 'Company Name',
            controller: _companyNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your company name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                text: 'Cancel',
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    // Reset controllers to original values
                    _companyNameController.text = _companyUser!.companyName;
                    _emailController.text = _companyUser!.email;
                  });
                },
                type: ButtonType.secondary,
              ),
              const SizedBox(width: 16),
              CustomButton(
                text: 'Save',
                onPressed: _updateProfile,
                isLoading: _isLoading,
                type: ButtonType.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsCard() {
    if (_companyUser == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Details', style: AppTheme.subheadingStyle),
            const Divider(height: 32),
            _buildInfoRow(
              'Account Created',
              dateFormat.format(_companyUser!.createdAt),
              icon: Icons.calendar_today,
            ),
            _buildInfoRow(
              'Last Updated',
              dateFormat.format(_companyUser!.updatedAt),
              icon: Icons.update,
            ),
            _buildInfoRow(
              'Account ID',
              _companyUser!.id.substring(0, 8),
              icon: Icons.badge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Actions', style: AppTheme.subheadingStyle),
            const Divider(height: 32),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: const Text('Reset Password'),
              subtitle: const Text('Update your account password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _initiatePasswordReset();
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: AppTheme.errorColor),
              ),
              title: const Text('Sign Out'),
              subtitle: const Text('Log out from your account'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
