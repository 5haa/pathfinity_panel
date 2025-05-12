import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/bottom_nav_scaffold.dart';
import 'package:admin_panel/screens/company/tabs/company_dashboard_tab.dart';
import 'package:admin_panel/screens/company/tabs/company_jobs_tab.dart';
import 'package:admin_panel/screens/company/tabs/company_profile_tab.dart';

class CompanyMainScreen extends ConsumerWidget {
  const CompanyMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavScaffold(
      title: 'Company Dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            try {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                GoRouter.of(context).go('/login');
              }
            } catch (e) {
              debugPrint('Error signing out: $e');
            }
          },
          tooltip: 'Sign Out',
        ),
      ],
      items: [
        BottomNavItem(
          label: 'Dashboard',
          icon: Icons.dashboard,
          screen: const CompanyDashboardTab(),
        ),
        BottomNavItem(
          label: 'Jobs',
          icon: Icons.work,
          screen: const CompanyJobsTab(),
        ),
        BottomNavItem(
          label: 'Profile',
          icon: Icons.business,
          screen: const CompanyProfileTab(),
        ),
      ],
    );
  }
}
