import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/bottom_nav_scaffold.dart';
import 'package:admin_panel/screens/alumni/tabs/alumni_dashboard_tab.dart';
import 'package:admin_panel/screens/alumni/tabs/alumni_chat_tab.dart';
import 'package:admin_panel/screens/alumni/tabs/alumni_profile_tab.dart';

class AlumniMainScreen extends ConsumerWidget {
  const AlumniMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavScaffold(
      title: 'Alumni Dashboard',
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
          screen: const AlumniDashboardTab(),
        ),
        BottomNavItem(
          label: 'Chat',
          icon: Icons.chat,
          screen: const AlumniChatTab(),
        ),
        BottomNavItem(
          label: 'Profile',
          icon: Icons.person,
          screen: const AlumniProfileTab(),
        ),
      ],
    );
  }
}
