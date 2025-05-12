import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController();
  final _experienceController = TextEditingController();
  final _graduationYearController = TextEditingController();

  UserType _selectedUserType = UserType.alumni;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _experienceController.dispose();
    _graduationYearController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = _getUserData();

      debugPrint(
        'Registering user: ${_emailController.text.trim()} with type: $_selectedUserType',
      );

      // Use the auth notifier to sign up
      await ref
          .read(authProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            userType: _selectedUserType,
            userData: userData,
          );

      debugPrint('User registered successfully, sending verification email');

      // Send verification email
      await ref
          .read(authProvider.notifier)
          .sendEmailVerification(_emailController.text.trim());

      debugPrint(
        'Verification email sent, proceeding to OTP verification screen',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please verify your email.'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate to OTP verification screen
        GoRouter.of(context).go(
          '/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}',
        );
      }
    } catch (e) {
      debugPrint('Error during registration: $e');
      setState(() {
        if (e is AuthException) {
          _errorMessage = e.message;
        } else {
          _errorMessage =
              'An error occurred during registration. Please try again.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getUserData() {
    switch (_selectedUserType) {
      case UserType.alumni:
        return {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'birthdate': _selectedDate?.toIso8601String(),
          'graduation_year':
              _graduationYearController.text.isNotEmpty
                  ? int.tryParse(_graduationYearController.text.trim())
                  : null,
          'university': _universityController.text.trim(),
          'experience': _experienceController.text.trim(),
        };
      case UserType.company:
        return {
          'company_name': _companyNameController.text.trim(),
          'email': _emailController.text.trim(),
        };
      case UserType.contentCreator:
        return {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'birthdate': _selectedDate?.toIso8601String(),
          'bio': _bioController.text.trim(),
          'phone': _phoneController.text.trim(),
        };
      default:
        return {};
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Create an Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // User Type Selection
                        const Text(
                          'Register as:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<UserType>(
                          segments: const [
                            ButtonSegment<UserType>(
                              value: UserType.alumni,
                              label: Text('Alumni'),
                              icon: Icon(Icons.school),
                            ),
                            ButtonSegment<UserType>(
                              value: UserType.company,
                              label: Text('Company'),
                              icon: Icon(Icons.business),
                            ),
                            ButtonSegment<UserType>(
                              value: UserType.contentCreator,
                              label: Text('Content Creator'),
                              icon: Icon(Icons.video_library),
                            ),
                          ],
                          selected: {_selectedUserType},
                          onSelectionChanged: (Set<UserType> selection) {
                            setState(() {
                              _selectedUserType = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Common Fields
                        CustomTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
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
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        const SizedBox(height: 16),

                        // User Type Specific Fields
                        if (_selectedUserType == UserType.alumni ||
                            _selectedUserType == UserType.contentCreator) ...[
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'First Name',
                                  hint: 'Enter your first name',
                                  controller: _firstNameController,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your first name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Last Name',
                                  hint: 'Enter your last name',
                                  controller: _lastNameController,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your last name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_selectedUserType == UserType.alumni) ...[
                          // Birthdate
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
                                onTap: () => _selectDate(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.secondaryColor,
                                    ),
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
                                        _selectedDate == null
                                            ? 'Select your birthdate'
                                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                        style: TextStyle(
                                          color:
                                              _selectedDate == null
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
                            hint: 'Enter your graduation year',
                            controller: _graduationYearController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
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
                            prefixIcon: const Icon(Icons.school),
                          ),
                          const SizedBox(height: 16),

                          // University
                          CustomTextField(
                            label: 'University/College',
                            hint: 'Enter your university or college name',
                            controller: _universityController,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(Icons.account_balance),
                          ),
                          const SizedBox(height: 16),

                          // Experience
                          CustomTextField(
                            label: 'Experience',
                            hint: 'Describe your professional experience',
                            controller: _experienceController,
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                            prefixIcon: const Icon(Icons.work),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_selectedUserType == UserType.company) ...[
                          CustomTextField(
                            label: 'Company Name',
                            hint: 'Enter your company name',
                            controller: _companyNameController,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your company name';
                              }
                              return null;
                            },
                            prefixIcon: const Icon(Icons.business),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_selectedUserType == UserType.contentCreator) ...[
                          // Birthdate
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
                                onTap: () => _selectDate(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.secondaryColor,
                                    ),
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
                                        _selectedDate == null
                                            ? 'Select your birthdate'
                                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                        style: TextStyle(
                                          color:
                                              _selectedDate == null
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

                          // Bio
                          CustomTextField(
                            label: 'Bio',
                            hint: 'Tell us about yourself',
                            controller: _bioController,
                            maxLines: 3,
                            keyboardType: TextInputType.multiline,
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          CustomTextField(
                            label: 'Phone',
                            hint: 'Enter your phone number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Password Fields
                        PasswordTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          controller: _passwordController,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        PasswordTextField(
                          label: 'Confirm Password',
                          hint: 'Confirm your password',
                          controller: _confirmPasswordController,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.errorColor),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        CustomButton(
                          text: 'Register',
                          onPressed: _register,
                          isLoading: _isLoading,
                          isFullWidth: true,
                          icon: Icons.person_add,
                        ),
                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () {
                            GoRouter.of(context).go('/login');
                          },
                          child: const Text(
                            'Already have an account? Login',
                            style: TextStyle(color: AppTheme.accentColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
