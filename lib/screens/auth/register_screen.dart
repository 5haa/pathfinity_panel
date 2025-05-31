import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:flutter/gestures.dart';

// Import component files
import 'package:admin_panel/screens/auth/register/user_type_selector.dart';
import 'package:admin_panel/screens/auth/register/common_fields.dart';
import 'package:admin_panel/screens/auth/register/alumni_form.dart';
import 'package:admin_panel/screens/auth/register/company_form.dart';
import 'package:admin_panel/screens/auth/register/content_creator_form.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  UserType _selectedUserType = UserType.alumni;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  void _selectUserType(UserType userType) {
    setState(() {
      _selectedUserType = userType;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.accentColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
      final email = _emailController.text.trim();
      final userData = _getUserData();

      debugPrint('Registering user: $email with type: $_selectedUserType');

      // Run diagnostic check on RLS policies
      final authService = AuthService();
      final policyDiagnostics = await authService.diagnosePolicyIssues();
      debugPrint('Policy diagnostics: $policyDiagnostics');

      // Check if user already exists
      final userExists = await authService.checkExistingUser(email);

      if (userExists) {
        setState(() {
          _errorMessage =
              'This email is already registered. Please try logging in instead or use a different email.';
          _isLoading = false;
        });
        return;
      }

      // Use the auth notifier to sign up
      await ref
          .read(authProvider.notifier)
          .signUp(
            email: email,
            password: _passwordController.text,
            userType: _selectedUserType,
            userData: userData,
          );

      debugPrint('Sign up completed');

      // Send verification email - Commenting this out as Supabase likely handles this
      // if "Confirm email" is enabled in project settings.
      // await ref.read(authProvider.notifier).sendEmailVerification(email);

      // debugPrint(
      //   'Verification email sent, router will redirect to OTP screen if needed',
      // );
      // The above debugPrint is also commented as it refers to the manual send.
      // A new debugPrint indicating reliance on automatic email can be added if desired.
      debugPrint('Assuming Supabase sent confirmation email/OTP upon signup.');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please verify your email.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      debugPrint('Error during registration: $e');
      if (!mounted) return;
      setState(() {
        if (e is AuthException) {
          _errorMessage = e.message;
        } else if (e.toString().contains('409')) {
          // Handle 409 Conflict error specifically
          _errorMessage =
              'This email is already registered. Please try logging in instead or use a different email.';
        } else {
          _errorMessage =
              'An error occurred during registration. Please try again: ${e.toString()}';
        }
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTabletOrLarger = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/login'),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join our platform',
                          style: Theme.of(
                            context,
                          ).textTheme.displayLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create an account to get started',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textLightColor),
                        ),
                      ],
                    ),
                  ),

                  // Main registration form
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: isTabletOrLarger ? 700 : double.infinity,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // User Type Selection
                          UserTypeSelector(
                            selectedUserType: _selectedUserType,
                            onUserTypeChanged: _selectUserType,
                          ),

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 32),

                          // Common Fields (Email & Password)
                          CommonRegistrationFields(
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                          ),

                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 32),

                          // User type specific fields
                          _buildUserTypeForm(),

                          const SizedBox(height: 32),

                          // Error message
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.errorColor.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppTheme.errorColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Register button
                          CustomButton(
                            text: 'Create Account',
                            onPressed: _register,
                            isLoading: _isLoading,
                            isFullWidth: true,
                            icon: Icons.person_add,
                          ),

                          const SizedBox(height: 24),

                          // Login link
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  color: AppTheme.textLightColor,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Log in',
                                    style: TextStyle(
                                      color: AppTheme.accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer:
                                        TapGestureRecognizer()
                                          ..onTap = () {
                                            GoRouter.of(context).go('/login');
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeForm() {
    switch (_selectedUserType) {
      case UserType.alumni:
        return AlumniRegistrationForm(
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          universityController: _universityController,
          graduationYearController: _graduationYearController,
          experienceController: _experienceController,
          selectedDate: _selectedDate,
          onSelectDate: () => _selectDate(context),
        );
      case UserType.company:
        return CompanyRegistrationForm(
          companyNameController: _companyNameController,
        );
      case UserType.contentCreator:
        return ContentCreatorRegistrationForm(
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          phoneController: _phoneController,
          bioController: _bioController,
          selectedDate: _selectedDate,
          onSelectDate: () => _selectDate(context),
        );
      default:
        return const SizedBox();
    }
  }
}
