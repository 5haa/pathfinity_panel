import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/services/company_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';
import 'package:admin_panel/services/auth_service.dart';

final companyServiceProvider = Provider<CompanyService>(
  (ref) => CompanyService(),
);

class CompanyDashboard extends ConsumerStatefulWidget {
  const CompanyDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends ConsumerState<CompanyDashboard> {
  CompanyUser? _companyUser;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isCreatingInternship = false;
  List<Map<String, dynamic>> _internships = [];

  final _formKey = GlobalKey<FormState>();
  final _internshipFormKey = GlobalKey<FormState>();

  late TextEditingController _companyNameController;
  late TextEditingController _emailController;

  // Internship form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _skillsController = TextEditingController();

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
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _skillsController.dispose();
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
        });

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

  Future<void> _createInternship() async {
    if (!_internshipFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final companyService = ref.read(companyServiceProvider);

      // Convert comma-separated skills to a list
      final skillsList =
          _skillsController.text
              .split(',')
              .map((skill) => skill.trim())
              .where((skill) => skill.isNotEmpty)
              .toList();

      final success = await companyService.createInternship(
        companyId: _companyUser!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        duration: _durationController.text.trim(),
        skills: skillsList,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internship created successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _durationController.clear();
        _skillsController.clear();

        // Reload internships
        await _loadInternships();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating internship: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while creating internship'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isCreatingInternship = false;
      });
    }
  }

  Future<void> _toggleInternshipStatus(
    String internshipId,
    bool currentStatus,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final companyService = ref.read(companyServiceProvider);
      final success = await companyService.updateInternshipStatus(
        internshipId: internshipId,
        isActive: !currentStatus,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? 'Internship deactivated successfully'
                  : 'Internship activated successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadInternships();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update internship status'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating internship status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred while updating internship status'),
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
        title: const Text('Company Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _companyUser == null
              ? const Center(child: Text('Error loading company profile'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 32),
                    _buildApprovalStatus(),
                    const SizedBox(height: 32),
                    _buildInternshipsSection(),
                  ],
                ),
              ),
      floatingActionButton:
          _companyUser != null && _companyUser!.isApproved
              ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _isCreatingInternship = true;
                  });
                },
                backgroundColor: AppTheme.accentColor,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Company Information', style: AppTheme.headingStyle),
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
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add profile picture
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: ProfilePictureWidget(
              userId: _companyUser!.id,
              name: _companyUser!.companyName,
              profilePictureUrl: _companyUser!.profilePictureUrl,
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
        // Existing profile info
        _buildInfoRow('Company Name', _companyUser!.companyName),
        _buildInfoRow('Email', _companyUser!.email),
        _buildInfoRow(
          'Account Status',
          _companyUser!.isApproved ? 'Approved' : 'Pending Approval',
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
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
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildApprovalStatus() {
    final isApproved = _companyUser!.isApproved;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Status', style: AppTheme.headingStyle),
            const SizedBox(height: 24),
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

  Widget _buildInternshipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Internships', style: AppTheme.headingStyle),
        const SizedBox(height: 16),
        if (_isCreatingInternship) _buildInternshipForm(),
        if (!_companyUser!.isApproved)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Your account needs to be approved before you can post internships.',
              style: TextStyle(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (_internships.isEmpty && !_isCreatingInternship)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'You haven\'t posted any internships yet.',
              style: TextStyle(
                color: AppTheme.textLightColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ..._internships.map(_buildInternshipCard).toList(),
      ],
    );
  }

  Widget _buildInternshipForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _internshipFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Internship',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Title',
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Duration',
                controller: _durationController,
                hint: 'e.g., 3 months, Summer 2025',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Skills (comma-separated)',
                controller: _skillsController,
                hint: 'e.g., Flutter, Dart, Firebase',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter at least one skill';
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
                        _isCreatingInternship = false;
                      });
                    },
                    type: ButtonType.secondary,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: 'Create',
                    onPressed: _createInternship,
                    isLoading: _isLoading,
                    type: ButtonType.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInternshipCard(Map<String, dynamic> internship) {
    final bool isActive = internship['is_active'] ?? false;
    final bool isApproved = internship['is_approved'] ?? false;
    final List<dynamic> skills = internship['skills'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    internship['title'] ?? 'Untitled Internship',
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
              internship['description'] ?? 'No description provided',
              style: const TextStyle(color: AppTheme.textColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.textLightColor,
                ),
                const SizedBox(width: 4),
                Text(
                  internship['duration'] ?? 'Duration not specified',
                  style: const TextStyle(color: AppTheme.textLightColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  skills
                      .map(
                        (skill) => Chip(
                          label: Text(
                            skill.toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey[200],
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: isActive ? 'Deactivate' : 'Activate',
                  onPressed:
                      () => _toggleInternshipStatus(internship['id'], isActive),
                  type: isActive ? ButtonType.warning : ButtonType.success,
                  height: 36,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
