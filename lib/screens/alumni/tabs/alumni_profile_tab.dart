import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/services/alumni_service.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:admin_panel/widgets/profile_picture_widget.dart';

final alumniServiceProvider = Provider<AlumniService>((ref) => AlumniService());

class AlumniProfileTab extends ConsumerStatefulWidget {
  const AlumniProfileTab({Key? key}) : super(key: key);

  @override
  ConsumerState<AlumniProfileTab> createState() => _AlumniProfileTabState();
}

class _AlumniProfileTabState extends ConsumerState<AlumniProfileTab> {
  AlumniUser? _alumniUser;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _universityController;
  late TextEditingController _graduationYearController;
  late TextEditingController _experienceController;
  DateTime? _selectedBirthdate;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _universityController = TextEditingController();
    _graduationYearController = TextEditingController();
    _experienceController = TextEditingController();
    _loadAlumniProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _universityController.dispose();
    _graduationYearController.dispose();
    _experienceController.dispose();
    super.dispose();
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
          _firstNameController.text = userProfile.firstName;
          _lastNameController.text = userProfile.lastName ?? '';
          _emailController.text = userProfile.email;
          _universityController.text = userProfile.university ?? '';
          _graduationYearController.text =
              userProfile.graduationYear?.toString() ?? '';
          _experienceController.text = userProfile.experience ?? '';
          _selectedBirthdate = userProfile.birthdate;
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
        _loadAlumniProfile();
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

  Future<void> _selectBirthdate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthdate = picked;
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
              userId: _alumniUser!.id,
              name: '${_alumniUser!.firstName} ${_alumniUser!.lastName ?? ''}',
              profilePictureUrl: _alumniUser!.profilePictureUrl ?? '',
              userType: UserType.alumni,
              size: 120,
              onPictureUpdated: (url) {
                setState(() {
                  _alumniUser = _alumniUser!.copyWith(profilePictureUrl: url);
                });
              },
            ),
          ),
        ),
        _buildInfoRow('First Name', _alumniUser!.firstName),
        _buildInfoRow('Last Name', _alumniUser!.lastName ?? ''),
        _buildInfoRow('Email', _alumniUser!.email),
        if (_alumniUser!.birthdate != null)
          _buildInfoRow(
            'Birthdate',
            '${_alumniUser!.birthdate!.day}/${_alumniUser!.birthdate!.month}/${_alumniUser!.birthdate!.year}',
          ),
        if (_alumniUser!.university != null &&
            _alumniUser!.university!.isNotEmpty)
          _buildInfoRow('University', _alumniUser!.university!),
        if (_alumniUser!.graduationYear != null)
          _buildInfoRow(
            'Graduation Year',
            _alumniUser!.graduationYear.toString(),
          ),
        if (_alumniUser!.experience != null &&
            _alumniUser!.experience!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Experience',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_alumniUser!.experience!),
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
                userId: _alumniUser!.id,
                name:
                    '${_alumniUser!.firstName} ${_alumniUser!.lastName ?? ''}',
                profilePictureUrl: _alumniUser!.profilePictureUrl ?? '',
                userType: UserType.alumni,
                size: 120,
                onPictureUpdated: (url) {
                  setState(() {
                    _alumniUser = _alumniUser!.copyWith(profilePictureUrl: url);
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
          // Birthdate field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Birthdate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectBirthdate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.secondaryColor),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedBirthdate == null
                            ? 'Select your birthdate'
                            : '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}',
                        style: TextStyle(
                          color:
                              _selectedBirthdate == null
                                  ? Colors.grey
                                  : AppTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Graduation Year
          CustomTextField(
            label: 'Graduation Year',
            controller: _graduationYearController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final year = int.tryParse(value);
                if (year == null) {
                  return 'Please enter a valid year';
                }
                if (year < 1950 || year > DateTime.now().year) {
                  return 'Please enter a valid graduation year';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // University
          CustomTextField(
            label: 'University/College',
            controller: _universityController,
            hint: 'Enter your university or college name',
          ),
          const SizedBox(height: 16),
          // Experience
          CustomTextField(
            label: 'Experience',
            controller: _experienceController,
            hint: 'Enter your skills or experience',
            maxLines: 3,
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
                    _firstNameController.text = _alumniUser!.firstName;
                    _lastNameController.text = _alumniUser!.lastName ?? '';
                    _emailController.text = _alumniUser!.email;
                    _universityController.text = _alumniUser!.university ?? '';
                    _graduationYearController.text =
                        _alumniUser!.graduationYear?.toString() ?? '';
                    _experienceController.text = _alumniUser!.experience ?? '';
                    _selectedBirthdate = _alumniUser!.birthdate;
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
