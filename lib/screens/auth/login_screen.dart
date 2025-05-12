import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  String? _errorMessage;

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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Attempting to sign in: ${_emailController.text.trim()}');

      // Use the auth notifier to sign in
      await ref
          .read(authProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Check if email is verified
      final isVerified =
          await ref.read(authProvider.notifier).isEmailVerified();

      debugPrint('Email verification status: $isVerified');

      if (!isVerified && mounted) {
        debugPrint('Email not verified, sending verification email');
        // Send a new verification email
        await ref
            .read(authProvider.notifier)
            .sendEmailVerification(_emailController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your email to continue.'),
            backgroundColor: AppTheme.infoColor,
          ),
        );

        // Navigate to OTP verification screen
        if (mounted) {
          debugPrint('Navigating to verification screen');
          GoRouter.of(context).go(
            '/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}',
          );
        }
      } else {
        debugPrint('Email verified, router will handle redirection');
        // If verified, the router will handle redirection based on user type
      }
    } catch (e) {
      debugPrint('Login error: $e');

      // Check if the error is specifically about email not being confirmed
      if (e is AuthException &&
          (e.message.contains('Email not confirmed') ||
              e.message.contains('Email hasn\'t been confirmed'))) {
        debugPrint('Caught unconfirmed email error, handling it');

        try {
          // Send a new verification email
          await ref
              .read(authProvider.notifier)
              .sendEmailVerification(_emailController.text.trim());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A verification code has been sent to your email.'),
              backgroundColor: AppTheme.infoColor,
            ),
          );

          // Navigate to OTP verification screen
          if (mounted) {
            debugPrint(
              'Navigating to verification screen after catching error',
            );
            GoRouter.of(context).go(
              '/verify-email?email=${Uri.encodeComponent(_emailController.text.trim())}',
            );
          }
        } catch (verificationError) {
          debugPrint('Error sending verification email: $verificationError');
          setState(() {
            _errorMessage =
                'Failed to send verification email. Please try again.';
          });
        }
      } else {
        // Handle other errors
        setState(() {
          if (e is AuthException) {
            _errorMessage = e.message;
          } else {
            _errorMessage = 'An error occurred during login. Please try again.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTabletOrLarger = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and header area
                    Column(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: isTabletOrLarger ? 120 : 90,
                          height: isTabletOrLarger ? 120 : 90,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: isTabletOrLarger ? 120 : 90,
                              height: isTabletOrLarger ? 120 : 90,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[600],
                                  size: isTabletOrLarger ? 70 : 50,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'pathfinity',
                          style: GoogleFonts.poppins(
                            textStyle: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Login to your account',
                      style: GoogleFonts.poppins(
                        textStyle: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Login form
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: isTabletOrLarger ? 450 : double.infinity,
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
                            CustomTextField(
                              label: 'Email',
                              hint: 'Enter your email address',
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
                            const SizedBox(height: 24),
                            PasswordTextField(
                              label: 'Password',
                              hint: 'Enter your password',
                              controller: _passwordController,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // Forgot password link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  GoRouter.of(context).go('/forgot-password');
                                },
                                child: const Text('Forgot Password?'),
                              ),
                            ),

                            const SizedBox(height: 16),

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

                            // Login button
                            CustomButton(
                              text: 'Login',
                              onPressed: _login,
                              isLoading: _isLoading,
                              isFullWidth: true,
                              icon: Icons.login,
                            ),

                            const SizedBox(height: 24),

                            // Register link
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Don\'t have an account? ',
                                  style: TextStyle(
                                    color: AppTheme.textLightColor,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Register here',
                                      style: TextStyle(
                                        color: AppTheme.accentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      recognizer:
                                          TapGestureRecognizer()
                                            ..onTap = () {
                                              GoRouter.of(
                                                context,
                                              ).go('/register');
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
      ),
    );
  }
}
