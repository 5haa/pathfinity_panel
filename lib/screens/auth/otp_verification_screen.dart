import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for TextInputFormatter
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({Key? key, required this.email})
    : super(key: key);

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  // Add mixin for animation
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _otpControllers;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  String? _errorMessage;
  bool _canResend = false;
  int _resendTimerSeconds = 60;
  Timer? _resendTimer;

  final int _otpLength = 6; // Define OTP length

  @override
  void initState() {
    super.initState();
    _initializeOtpFields();
    _startResendTimer();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  void _initializeOtpFields() {
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _otpControllers = List.generate(_otpLength, (_) => TextEditingController());

    for (int i = 0; i < _otpLength; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 && i < _otpLength - 1) {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        } else if (_otpControllers[i].text.isEmpty && i > 0) {
          // Move focus back on backspace
        }
      });
    }
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimerSeconds = 60;
    _resendTimer?.cancel(); // Cancel any existing timer
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendTimerSeconds > 0) {
          _resendTimerSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getEnteredOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
    // Prevent multiple verification attempts
    if (_isLoading) {
      debugPrint(
        'Verification already in progress, ignoring duplicate request',
      );
      return;
    }

    final enteredOtp = _getEnteredOtp();
    if (enteredOtp.length != _otpLength) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code.';
      });
      return;
    }

    // Store email locally to avoid accessing widget later
    final email = widget.email;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Verifying OTP for email: $email');

      // First check if email is already verified to avoid unnecessary verification
      final isAlreadyVerified =
          await ref.read(authProvider.notifier).isEmailVerified();

      // Before we do anything with state or navigation, check if widget is still mounted
      if (!mounted) return;

      if (isAlreadyVerified) {
        debugPrint('Email is already verified, skipping OTP verification');

        setState(() {
          _isLoading = false;
        });

        // Show success message and navigate
        _showSuccessAndNavigate();
        return;
      }

      // Try to verify the OTP
      final success = await ref
          .read(authProvider.notifier)
          .verifyOTP(email, enteredOtp);

      // Immediately check if widget is still mounted
      if (!mounted) return;

      debugPrint('OTP verification result: $success');

      setState(() {
        _isLoading = false;
      });

      if (success) {
        _showSuccessAndNavigate();
      } else {
        // Double-check the verification status before showing error
        final lastChance =
            await ref.read(authProvider.notifier).isEmailVerified();

        // Check mounted again after async operation
        if (!mounted) return;

        if (lastChance) {
          debugPrint('OTP verification succeeded on secondary check');
          _showSuccessAndNavigate();
        } else {
          setState(() {
            _errorMessage = 'Invalid verification code. Please try again.';
          });
        }
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');

      // Always check mounted before accessing state or context
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Check if the error message suggests the user might actually be verified
      if (e.toString().contains('User already confirmed') ||
          e.toString().contains('already confirmed') ||
          e.toString().contains('already verified')) {
        _showSuccessAndNavigate();
      } else {
        setState(() {
          _errorMessage =
              'Failed to verify OTP: ${e.toString().split(']').last.trim()}';
        });
      }
    }
  }

  // Show success message and initiate navigation
  void _showSuccessAndNavigate() {
    if (!mounted) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified successfully!'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    // Get navigation information before any navigation starts
    final userTypeInfo = ref.read(userTypeInfoProvider);
    final userType = userTypeInfo?.userType;
    final isApproved = userTypeInfo?.isApproved ?? false;
    String navigationPath = '/login'; // Default fallback

    debugPrint(
      'User type info after verification: $userType, Approved: $isApproved',
    );

    // Determine where to navigate
    if (userTypeInfo != null && !isApproved) {
      debugPrint(
        'User requires approval, will navigate to waiting approval screen',
      );
      navigationPath = '/waiting-approval';
    } else if (userTypeInfo != null) {
      switch (userType) {
        case UserType.admin:
          navigationPath = '/admin';
          break;
        case UserType.alumni:
          navigationPath = '/alumni/chat';
          break;
        case UserType.company:
          navigationPath = '/company';
          break;
        case UserType.contentCreator:
          navigationPath = '/content-creator';
          break;
        default:
          navigationPath = '/login';
      }
    }

    // Navigate using a post-frame callback to ensure it happens after the current build
    final BuildContext currentContext = context;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // First check if the widget is still mounted
        if (!mounted) return;

        debugPrint('Navigating to: $navigationPath');

        // First try to get the GoRouter instance from the saved context
        final router = GoRouter.of(currentContext);
        router.go(navigationPath);
      } catch (e) {
        debugPrint('Error during navigation: $e');
        // Fallback navigation if GoRouter fails
        try {
          if (mounted) {
            GoRouter.of(context).go(navigationPath);
          }
        } catch (e2) {
          debugPrint('Fallback navigation also failed: $e2');
        }
      }
    });
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).sendEmailVerification(widget.email);
      if (!mounted) return; // Check mounted after await

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Please check your inbox.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      _startResendTimer(); // Restart the timer
    } catch (e) {
      if (!mounted) return; // Check mounted after await in catch
      setState(() {
        _errorMessage = 'Failed to send verification email. Please try again.';
      });
    } finally {
      if (!mounted) return; // Check mounted after await in finally
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTabletOrLarger = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: AppTheme.surfaceColor, // Match theme
        foregroundColor: AppTheme.textColor, // Match theme
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              GoRouter.of(context).go('/login'); // Fallback if cannot pop
            }
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isTabletOrLarger ? 450 : double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppTheme.accentColor,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      Text(
                        'Enter Verification Code',
                        style: Theme.of(
                          context,
                        ).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Subtitle message
                      Text(
                        'We\'ve sent a 6-digit code to\n${widget.email}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLightColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // OTP Input Fields
                      _buildOtpInputFields(context),
                      const SizedBox(height: 24),
                      // Error message display
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppTheme.errorColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Verify Button
                      CustomButton(
                        text: 'Verify Email',
                        onPressed: () {
                          if (!_isLoading) {
                            _verifyOTP();
                          }
                        },
                        isLoading: _isLoading,
                        isFullWidth: true,
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(height: 24),
                      // Resend Code Section
                      Center(
                        child:
                            _canResend
                                ? TextButton(
                                  onPressed: _resendOTP,
                                  child: const Text('Resend Code'),
                                )
                                : RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textLightColor,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Resend code in '),
                                      TextSpan(
                                        text: '${_resendTimerSeconds}s',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
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
      ),
    );
  }

  // Helper to build OTP input fields row
  Widget _buildOtpInputFields(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppTheme.secondaryColor.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppTheme.accentColor,
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.length == 1 && index < _otpLength - 1) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                // Handle backspace: move focus to previous field
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              }

              // Verify if all fields are filled, but only if not already loading
              final enteredOtp = _getEnteredOtp();
              if (enteredOtp.length == _otpLength && !_isLoading) {
                // Use a delayed verification to avoid widget deactivation issues
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_isLoading) {
                    debugPrint('Auto-triggering OTP verification');
                    _verifyOTP();
                  }
                });
              }
            },
          ),
        );
      }),
    );
  }
}
