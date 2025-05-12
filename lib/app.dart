import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_panel/config/theme.dart';
import 'package:admin_panel/router.dart';
import 'package:admin_panel/screens/splash_screen.dart';

class AdminPanelApp extends ConsumerStatefulWidget {
  const AdminPanelApp({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminPanelApp> createState() => _AdminPanelAppState();
}

class _AdminPanelAppState extends ConsumerState<AdminPanelApp>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _hideSplash() {
    _fadeController.forward().then((_) {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    if (_showSplash) {
      return MaterialApp(
        title: 'Admin Panel',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: FadeTransition(
          opacity: _fadeAnimation,
          child: SplashScreen(onAnimationComplete: _hideSplash),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Admin Panel',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
