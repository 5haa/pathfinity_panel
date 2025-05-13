import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/widgets/bottom_nav_scaffold.dart';
import 'package:admin_panel/screens/alumni/tabs/alumni_chat_tab.dart';
import 'package:admin_panel/screens/alumni/tabs/alumni_profile_tab.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/screens/alumni/tabs/alumni_students_tab.dart';

class AlumniMainScreen extends ConsumerStatefulWidget {
  final String? tabParam;

  const AlumniMainScreen({Key? key, this.tabParam}) : super(key: key);

  @override
  ConsumerState<AlumniMainScreen> createState() => _AlumniMainScreenState();
}

class _AlumniMainScreenState extends ConsumerState<AlumniMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _handleTabParam();
  }

  @override
  void didUpdateWidget(AlumniMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabParam != oldWidget.tabParam) {
      _handleTabParam();
    }
  }

  void _handleTabParam() {
    if (widget.tabParam == 'chat') {
      setState(() {
        _currentIndex = 0; // Chat tab
      });
    } else if (widget.tabParam == 'students') {
      setState(() {
        _currentIndex = 1; // Students tab
      });
    } else if (widget.tabParam == 'profile') {
      setState(() {
        _currentIndex = 2; // Profile tab
      });
    } else {
      setState(() {
        _currentIndex = 0; // Default to chat tab
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavScaffold(
      title: 'Alumni Portal',
      initialIndex: _currentIndex,
      onTabChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
        // Update the URL to match the selected tab
        switch (index) {
          case 0:
            GoRouter.of(context).go('/alumni/chat');
            break;
          case 1:
            GoRouter.of(context).go('/alumni/students');
            break;
          case 2:
            GoRouter.of(context).go('/alumni/profile');
            break;
        }
      },
      items: [
        BottomNavItem(
          label: 'Chat',
          icon: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/chat.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          isIconData: false,
          screen: const AlumniChatTab(),
        ),
        BottomNavItem(
          label: 'Students',
          icon: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/student.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          isIconData: false,
          screen: const AlumniStudentsTab(),
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
          screen: const AlumniProfileTab(),
        ),
      ],
    );
  }
}
