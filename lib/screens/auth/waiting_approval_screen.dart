import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/widgets/custom_button.dart';

class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WaitingApprovalScreen> createState() =>
      _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    super.dispose();
  }

  void _signOut() async {
    await ref.read(authProvider.notifier).signOut();
    if (mounted) {
      GoRouter.of(context).go('/login');
    }
  }

  void _refreshStatus() async {
    await ref.read(authProvider.notifier).refreshUserTypeAndStatus();
    // The router will automatically redirect if the user is now approved
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTabletOrLarger = size.width > 600;
    final userTypeInfo = ref.watch(userTypeInfoProvider);
    final userType = userTypeInfo?.userType;

    String userTypeString = 'user';
    switch (userType) {
      case UserType.admin:
        userTypeString = 'admin';
        break;
      case UserType.alumni:
        userTypeString = 'alumni';
        break;
      case UserType.company:
        userTypeString = 'company';
        break;
      case UserType.contentCreator:
        userTypeString = 'content creator';
        break;
      default:
        userTypeString = 'user';
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Account Pending Approval'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
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
                    maxWidth: isTabletOrLarger ? 500 : double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Waiting icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.infoColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_top,
                          color: AppTheme.infoColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Your Account is Pending Approval',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Message
                      Text(
                        'Thank you for registering as a $userTypeString. Your account is currently under review by our administrators.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textLightColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'You will be able to access the platform once your account has been approved. This process usually takes 1-2 business days.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textLightColor,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Refresh button
                      CustomButton(
                        text: 'Check Approval Status',
                        onPressed: _refreshStatus,
                        isFullWidth: true,
                        icon: Icons.refresh,
                      ),

                      const SizedBox(height: 16),

                      // Sign out button
                      TextButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textLightColor,
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
}
