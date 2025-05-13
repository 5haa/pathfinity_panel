import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/widgets/bottom_nav_scaffold.dart';
import 'package:admin_panel/screens/content_creator/tabs/content_creator_dashboard_tab.dart';
import 'package:admin_panel/screens/content_creator/tabs/content_creator_courses_tab.dart';
import 'package:admin_panel/screens/content_creator/tabs/content_creator_profile_tab.dart';
import 'package:admin_panel/config/theme.dart';

// Custom controller to provide tab navigation across the bottom nav bar
final contentCreatorTabIndexProvider = StateProvider<int>((ref) => 0);

class ContentCreatorMainScreen extends ConsumerWidget {
  const ContentCreatorMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTabIndex = ref.watch(contentCreatorTabIndexProvider);

    return BottomNavScaffold(
      title: 'Content Creator Dashboard',
      initialIndex: currentTabIndex,
      onTabChanged: (index) {
        ref.read(contentCreatorTabIndexProvider.notifier).state = index;
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
          screen: const ContentCreatorDashboardTab(),
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
          screen: const ContentCreatorCoursesTab(),
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
          screen: const ContentCreatorProfileTab(),
        ),
      ],
    );
  }
}
