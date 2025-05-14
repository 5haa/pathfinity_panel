import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/bottom_nav_scaffold.dart';
import 'package:admin_panel/screens/admin/tabs/admin_dashboard_tab.dart';
import 'package:admin_panel/screens/admin/tabs/admin_users_tab.dart';
import 'package:admin_panel/screens/admin/tabs/admin_courses_tab.dart';
import 'package:admin_panel/screens/admin/tabs/admin_internships_tab.dart';
import 'package:admin_panel/screens/admin/tabs/admin_profile_tab.dart';
import 'package:admin_panel/config/theme.dart';

// Custom controller to provide tab navigation across the bottom nav bar
final adminCurrentTabIndexProvider = StateProvider<int>((ref) => 0);

class AdminMainScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const AdminMainScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  @override
  void initState() {
    super.initState();
    // Set the initial tab indices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTab != 0) {
        ref.read(adminCurrentTabIndexProvider.notifier).state =
            widget.initialTab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(adminCurrentTabIndexProvider);

    return BottomNavScaffold(
      title: 'Admin Dashboard',
      initialIndex: currentTabIndex,
      onTabChanged: (index) {
        ref.read(adminCurrentTabIndexProvider.notifier).state = index;
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
          screen: const AdminDashboardTab(),
        ),
        BottomNavItem(
          label: 'Users',
          icon: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/users.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          isIconData: false,
          screen: const AdminUsersTab(),
        ),
        BottomNavItem(
          label: 'Courses',
          icon: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/course.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          isIconData: false,
          screen: const AdminCoursesTab(),
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
          screen: const AdminInternshipsTab(),
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
          screen: const AdminProfileTab(),
        ),
      ],
    );
  }
}
