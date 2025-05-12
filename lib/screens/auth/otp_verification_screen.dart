import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';
import 'package:admin_panel/widgets/custom_text_field.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({Key? key, required this.email})
    : super(key: key);

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Verifying OTP for email: ${widget.email}');

      final success = await ref
          .read(authProvider.notifier)
          .verifyOTP(widget.email, _otpController.text.trim());

      debugPrint('OTP verification result: $success');

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Navigate to appropriate screen based on user type
        final userTypeInfo = ref.read(userTypeInfoProvider);
        debugPrint(
          'User type info after verification: ${userTypeInfo?.userType}',
        );

        if (userTypeInfo != null) {
          switch (userTypeInfo.userType) {
            case UserType.admin:
              debugPrint('Navigating to admin dashboard');
              GoRouter.of(context).go('/admin');
              break;
            case UserType.alumni:
              debugPrint('Navigating to alumni dashboard');
              GoRouter.of(context).go('/alumni');
              break;
            case UserType.company:
              debugPrint('Navigating to company dashboard');
              GoRouter.of(context).go('/company');
              break;
            case UserType.contentCreator:
              debugPrint('Navigating to content creator dashboard');
              GoRouter.of(context).go('/content-creator');
              break;
            default:
              debugPrint('Unknown user type, navigating to login screen');
              GoRouter.of(context).go('/login');
          }
        } else {
          debugPrint('No user type info found, navigating to login screen');
          GoRouter.of(context).go('/login');
        }
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      setState(() {
        _errorMessage = 'Failed to verify OTP. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).sendEmailVerification(widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send verification email. Please try again.';
      });
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
      appBar: AppBar(
        title: const Text('Email Verification'),
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
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'We\'ve sent a verification code to ${widget.email}. Please enter the code below to verify your email address.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        CustomTextField(
                          label: 'Verification Code',
                          hint: 'Enter the code from your email',
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the verification code';
                            }
                            return null;
                          },
                          prefixIcon: const Icon(Icons.security),
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
                          text: 'Verify Email',
                          onPressed: _verifyOTP,
                          isLoading: _isLoading,
                          isFullWidth: true,
                          icon: Icons.check_circle,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _resendOTP,
                          child: const Text(
                            'Didn\'t receive the code? Resend',
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
