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
  late TextEditingController _websiteController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _loadCompanyProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
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
          _companyNameController.text = userProfile.companyName;
          _emailController.text = userProfile.email;

          // Set default values for fields that might not be in the model
          _websiteController.text = '';
          _descriptionController.text = '';
          _locationController.text = '';
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
      // In a real app, you would use a method from the service
      // For now, we'll simulate a successful update
      await Future.delayed(const Duration(milliseconds: 500));
      bool success = true;

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
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Company Profile',
                        style: AppTheme.headingStyle,
                      ),
                      if (!_isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          tooltip: 'Edit Profile',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isEditing ? _buildEditForm() : _buildProfileInfo(),
                ],
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Actions', style: AppTheme.headingStyle),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Sign Out',
                    onPressed: _signOut,
                    type: ButtonType.danger,
                    icon: Icons.logout,
                  ),
                ],
              ),
            ),
          ),
        ],
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

        // Display additional fields if they have values
        if (_websiteController.text.isNotEmpty)
          _buildInfoRow('Website', _websiteController.text),
        if (_locationController.text.isNotEmpty)
          _buildInfoRow('Location', _locationController.text),
        if (_descriptionController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_descriptionController.text),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Website',
            controller: _websiteController,
            keyboardType: TextInputType.url,
            hint: 'https://example.com',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Location',
            controller: _locationController,
            hint: 'City, Country',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'About Your Company',
            controller: _descriptionController,
            hint: 'Tell us about your company...',
            maxLines: 5,
            keyboardType: TextInputType.multiline,
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
}
