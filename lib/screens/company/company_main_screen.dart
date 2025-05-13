import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/widgets/bottom_nav_scaffold.dart';
import 'package:admin_panel/screens/company/tabs/company_dashboard_tab.dart';
import 'package:admin_panel/screens/company/tabs/company_jobs_tab.dart';
import 'package:admin_panel/screens/company/tabs/company_profile_tab.dart';
import 'package:admin_panel/config/theme.dart';

// Custom controller to provide tab navigation across the bottom nav bar
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

class CompanyMainScreen extends ConsumerWidget {
  const CompanyMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTabIndex = ref.watch(currentTabIndexProvider);

    return BottomNavScaffold(
      title: 'Company Dashboard',
      initialIndex: currentTabIndex,
      onTabChanged: (index) {
        ref.read(currentTabIndexProvider.notifier).state = index;
      },
      items: [
        BottomNavItem(
          label: 'Dashboard',
          icon: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/dashboard.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          isIconData: false,
          screen: CompanyDashboardTab(
            onViewAllInternships: () {
              // Navigate to internships tab
              ref.read(currentTabIndexProvider.notifier).state = 1;
            },
          ),
        ),
        BottomNavItem(
          label: 'Internships',
          icon: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/internships.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          isIconData: false,
          screen: const CompanyJobsTab(),
        ),
        BottomNavItem(
          label: 'Profile',
          icon: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/profile.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          isIconData: false,
          screen: const CompanyProfileTab(),
        ),
      ],
    );
  }
}
