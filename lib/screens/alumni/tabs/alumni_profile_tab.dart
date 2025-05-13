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
import 'package:intl/intl.dart';

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
  bool _isSaving = false;

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
          _updateControllers();
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

  void _updateControllers() {
    if (_alumniUser == null) return;

    _firstNameController.text = _alumniUser!.firstName;
    _lastNameController.text = _alumniUser!.lastName;
    _emailController.text = _alumniUser!.email;
    _universityController.text = _alumniUser!.university ?? '';
    _graduationYearController.text =
        _alumniUser!.graduationYear?.toString() ?? '';
    _experienceController.text = _alumniUser!.experience ?? '';
    _selectedBirthdate = _alumniUser!.birthdate;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() != true || _alumniUser == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      int? graduationYear;
      if (_graduationYearController.text.isNotEmpty) {
        graduationYear = int.tryParse(_graduationYearController.text);
      }

      final success = await ref
          .read(alumniServiceProvider)
          .updateProfile(
            userId: _alumniUser!.id,
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            email: _emailController.text,
            birthdate: _selectedBirthdate,
            graduationYear: graduationYear,
            university:
                _universityController.text.isNotEmpty
                    ? _universityController.text
                    : null,
            experience:
                _experienceController.text.isNotEmpty
                    ? _experienceController.text
                    : null,
          );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        await _loadAlumniProfile();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
    }
  }

  Future<void> _pickBirthdate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthdate = pickedDate;
      });
    }
  }

  Future<void> _initiatePasswordReset() async {
    try {
      if (_alumniUser != null) {
        // Navigate to the forgot password screen with the email pre-filled
        GoRouter.of(context).go('/forgot-password');

        // Show a message to the user
        if (context.mounted) {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
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

    if (_alumniUser == null) {
      return const Center(child: Text('Error loading alumni profile'));
    }

    return RefreshIndicator(
      onRefresh: _loadAlumniProfile,
      child: SingleChildScrollView(
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
                const Text('Alumni Profile', style: AppTheme.headingStyle),
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
              userId: _alumniUser!.id,
              name: '${_alumniUser!.firstName} ${_alumniUser!.lastName}',
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
        _buildInfoRow('Last Name', _alumniUser!.lastName),
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
            _alumniUser!.experience!.isNotEmpty)
          _buildInfoRow('Experience', _alumniUser!.experience!),
        _buildInfoRow(
          'Account Status',
          _alumniUser!.isApproved ? 'Approved' : 'Pending Approval',
          icon: _alumniUser!.isApproved ? Icons.check_circle : Icons.pending,
          iconColor:
              _alumniUser!.isApproved
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
                userId: _alumniUser!.id,
                name: '${_alumniUser!.firstName} ${_alumniUser!.lastName}',
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
          _buildBirthdatePicker(),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'University',
            controller: _universityController,
          ),
          const SizedBox(height: 16),
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
                if (year < 1950 || year > DateTime.now().year + 10) {
                  return 'Please enter a reasonable graduation year';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Experience',
            controller: _experienceController,
            maxLines: 4,
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
                    _updateControllers(); // Reset form to original values
                  });
                },
                type: ButtonType.secondary,
              ),
              const SizedBox(width: 16),
              CustomButton(
                text: _isSaving ? 'Saving...' : 'Save',
                onPressed: _saveButtonPressed,
                isLoading: _isSaving,
                type: ButtonType.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdatePicker() {
    return InkWell(
      onTap: _pickBirthdate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birthdate',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedBirthdate != null
                  ? '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}'
                  : 'Select Birthdate',
              style: TextStyle(
                color:
                    _selectedBirthdate != null
                        ? AppTheme.textColor
                        : Colors.grey[600],
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetailsCard() {
    if (_alumniUser == null) return const SizedBox.shrink();

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
              dateFormat.format(_alumniUser!.createdAt),
              icon: Icons.calendar_today,
            ),
            _buildInfoRow(
              'Last Updated',
              dateFormat.format(_alumniUser!.updatedAt),
              icon: Icons.update,
            ),
            _buildInfoRow(
              'Account ID',
              _alumniUser!.id.substring(0, 8),
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
              onTap: () async {
                try {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    GoRouter.of(context).go('/login');
                  }
                } catch (e) {
                  debugPrint('Error signing out: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveButtonPressed() {
    if (!_isSaving) {
      _saveProfile();
    }
  }
}
