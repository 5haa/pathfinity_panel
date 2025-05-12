import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/content_creator_model.dart';
import 'package:admin_panel/services/content_creator_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';

final contentCreatorServiceProvider = Provider<ContentCreatorService>(
  (ref) => ContentCreatorService(),
);

class ContentCreatorProfileTab extends ConsumerStatefulWidget {
  const ContentCreatorProfileTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ContentCreatorProfileTab> createState() =>
      _ContentCreatorProfileTabState();
}

class _ContentCreatorProfileTabState
    extends ConsumerState<ContentCreatorProfileTab> {
  ContentCreatorUser? _contentCreatorUser;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _specialtyController;
  late TextEditingController _bioController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _specialtyController = TextEditingController();
    _bioController = TextEditingController();
    _websiteController = TextEditingController();
    _loadContentCreatorProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    _bioController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadContentCreatorProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the auth service from the provider
      final userProfile = await ref.read(authServiceProvider).getUserProfile();

      if (userProfile is ContentCreatorUser) {
        setState(() {
          _contentCreatorUser = userProfile;
          _firstNameController.text = userProfile.firstName;
          _lastNameController.text = userProfile.lastName ?? '';
          _emailController.text = userProfile.email;

          // Set default values for fields that might not be in the model
          _specialtyController.text = '';
          _bioController.text = '';
          _websiteController.text = '';
        });
      }
    } catch (e) {
      debugPrint('Error loading content creator profile: $e');
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
        _loadContentCreatorProfile();
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

    if (_contentCreatorUser == null) {
      return const Center(child: Text('Error loading content creator profile'));
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
                        'Profile Information',
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
              userId: _contentCreatorUser!.id,
              name:
                  '${_contentCreatorUser!.firstName} ${_contentCreatorUser!.lastName ?? ''}',
              profilePictureUrl: _contentCreatorUser!.profilePictureUrl ?? '',
              userType: UserType.contentCreator,
              size: 120,
              onPictureUpdated: (url) {
                setState(() {
                  _contentCreatorUser = _contentCreatorUser!.copyWith(
                    profilePictureUrl: url,
                  );
                });
              },
            ),
          ),
        ),
        _buildInfoRow('First Name', _contentCreatorUser!.firstName),
        _buildInfoRow('Last Name', _contentCreatorUser!.lastName ?? ''),
        _buildInfoRow('Email', _contentCreatorUser!.email),

        // Display additional fields if they have values
        if (_specialtyController.text.isNotEmpty)
          _buildInfoRow('Specialty', _specialtyController.text),
        if (_websiteController.text.isNotEmpty)
          _buildInfoRow('Website', _websiteController.text),
        if (_bioController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_bioController.text),
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
                userId: _contentCreatorUser!.id,
                name:
                    '${_contentCreatorUser!.firstName} ${_contentCreatorUser!.lastName ?? ''}',
                profilePictureUrl: _contentCreatorUser!.profilePictureUrl ?? '',
                userType: UserType.contentCreator,
                size: 120,
                onPictureUpdated: (url) {
                  setState(() {
                    _contentCreatorUser = _contentCreatorUser!.copyWith(
                      profilePictureUrl: url,
                    );
                  });
                },
              ),
            ),
          ),
          CustomTextField(
            label: 'First Name',
            controller: _firstNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Last Name',
            controller: _lastNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
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
            label: 'Specialty',
            controller: _specialtyController,
            hint: 'e.g. Web Development, Data Science, Mobile Apps',
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
            label: 'Bio',
            controller: _bioController,
            hint: 'Tell students about yourself...',
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
                    _firstNameController.text = _contentCreatorUser!.firstName;
                    _lastNameController.text =
                        _contentCreatorUser!.lastName ?? '';
                    _emailController.text = _contentCreatorUser!.email;
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
