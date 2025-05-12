import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/bottom_nav_scaffold.dart';
import 'package:admin_panel/screens/content_creator/tabs/content_creator_dashboard_tab.dart';
import 'package:admin_panel/screens/content_creator/tabs/content_creator_courses_tab.dart';
import 'package:admin_panel/screens/content_creator/tabs/content_creator_profile_tab.dart';

class ContentCreatorMainScreen extends ConsumerWidget {
  const ContentCreatorMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavScaffold(
      title: 'Content Creator Dashboard',
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
          screen: const ContentCreatorDashboardTab(),
        ),
        BottomNavItem(
          label: 'Courses',
          icon: Icons.book,
          screen: const ContentCreatorCoursesTab(),
        ),
        BottomNavItem(
          label: 'Profile',
          icon: Icons.person,
          screen: const ContentCreatorProfileTab(),
        ),
      ],
    );
  }
}
