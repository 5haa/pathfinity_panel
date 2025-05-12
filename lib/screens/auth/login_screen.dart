import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
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
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Admin Panel Login',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
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
                          text: 'Login',
                          onPressed: _login,
                          isLoading: _isLoading,
                          isFullWidth: true,
                          icon: Icons.login,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // Navigate to registration screen
                            GoRouter.of(context).go('/register');
                          },
                          child: const Text(
                            'Don\'t have an account? Register',
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
