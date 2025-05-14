import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/screens/auth/login_screen.dart';
import 'package:admin_panel/screens/auth/register_screen.dart';
import 'package:admin_panel/screens/auth/otp_verification_screen.dart';
import 'package:admin_panel/screens/auth/forgot_password_screen.dart';
import 'package:admin_panel/screens/auth/reset_password_otp_screen.dart';
import 'package:admin_panel/screens/admin/admin_main_screen.dart';
import 'package:admin_panel/screens/admin/admin_course_management_screen.dart';
import 'package:admin_panel/screens/admin/admin_course_videos_screen.dart';
import 'package:admin_panel/screens/alumni/alumni_main_screen.dart';
import 'package:admin_panel/screens/alumni/student_profile_screen.dart';
import 'package:admin_panel/screens/alumni/chat_screen.dart';
import 'package:admin_panel/screens/company/company_main_screen.dart';
import 'package:admin_panel/screens/content_creator/content_creator_main_screen.dart';
import 'package:admin_panel/screens/content_creator/course_videos_screen.dart';
import 'package:admin_panel/screens/content_creator/go_live_screen.dart';
import 'package:admin_panel/screens/content_creator/broadcast_screen.dart';
import 'package:admin_panel/screens/content_creator/live_sessions_screen.dart';
import 'package:admin_panel/screens/content_creator/schedule_live_screen.dart';
import 'package:admin_panel/models/live_session_model.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/services/auth_service.dart';
import 'package:admin_panel/screens/admin/gift_card_management_screen.dart';
import 'package:admin_panel/screens/admin/category_management_screen.dart';

// Custom page transition
class FadeTransitionPage extends CustomTransitionPage<void> {
  FadeTransitionPage({required LocalKey key, required Widget child})
    : super(
        key: key,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
            child: child,
          );
        },
        child: child,
      );
}

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      // Check if the user is logged in
      final loggedIn = ref.read(isLoggedInProvider);
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isVerifyEmailRoute = state.matchedLocation.startsWith(
        '/verify-email',
      );
      final isForgotPasswordRoute = state.matchedLocation == '/forgot-password';
      final isResetPasswordOtpRoute = state.matchedLocation.startsWith(
        '/reset-password-otp',
      );

      debugPrint(
        'Router redirect - Current location: ${state.matchedLocation}, User logged in: $loggedIn',
      );

      // If not logged in and not on auth pages, redirect to login
      if (!loggedIn &&
          !isLoginRoute &&
          !isRegisterRoute &&
          !isVerifyEmailRoute &&
          !isForgotPasswordRoute &&
          !isResetPasswordOtpRoute) {
        debugPrint('Router redirect - Not logged in, redirecting to login');
        return '/login';
      }

      // If logged in and on login or register page, redirect to dashboard
      if (loggedIn && (isLoginRoute || isRegisterRoute)) {
        // Get user type to determine which dashboard to show
        final userTypeInfo = ref.read(userTypeInfoProvider);
        debugPrint(
          'Router redirect - Logged in user with type: ${userTypeInfo?.userType}',
        );

        if (userTypeInfo == null) {
          // If user type info is not available, sign out and redirect to login
          debugPrint('Router redirect - No user type info, signing out');
          await authNotifier.signOut();
          return '/login';
        }

        switch (userTypeInfo.userType) {
          case UserType.admin:
            debugPrint('Router redirect - Redirecting to admin dashboard');
            return '/admin';
          case UserType.alumni:
            debugPrint('Router redirect - Redirecting to alumni dashboard');
            return '/alumni/chat';
          case UserType.company:
            debugPrint('Router redirect - Redirecting to company dashboard');
            return '/company';
          case UserType.contentCreator:
            debugPrint(
              'Router redirect - Redirecting to content creator dashboard',
            );
            return '/content-creator';
          default:
            // If user type is unknown, sign out and redirect to login
            debugPrint('Router redirect - Unknown user type, signing out');
            await authNotifier.signOut();
            return '/login';
        }
      }

      // No redirect needed
      debugPrint('Router redirect - No redirect needed');
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const RegisterScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: OtpVerificationScreen(email: email),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ForgotPasswordScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/reset-password-otp',
        pageBuilder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ResetPasswordOtpScreen(email: email),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),

      // Dashboard routes
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AdminMainScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/admin/categories',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const CategoryManagementScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/admin/gift-cards',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const GiftCardManagementScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/admin/courses/:courseId/management',
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final courseTitle = extra?['courseTitle'] as String? ?? 'Course';

          return CustomTransitionPage(
            key: state.pageKey,
            child: AdminCourseManagementScreen(
              courseId: courseId,
              courseTitle: courseTitle,
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/admin/courses/:courseId/videos',
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final Map<String, dynamic>? extra =
              state.extra as Map<String, dynamic>?;
          final courseTitle = extra?['courseTitle'] as String? ?? 'Course';

          return CustomTransitionPage(
            key: state.pageKey,
            child: AdminCourseVideosScreen(
              courseId: courseId,
              courseTitle: courseTitle,
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      // Alumni routes
      GoRoute(path: '/alumni', redirect: (context, state) => '/alumni/chat'),
      GoRoute(
        path: '/alumni/chat',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AlumniMainScreen(tabParam: 'chat'),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/alumni/students',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AlumniMainScreen(tabParam: 'students'),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/alumni/profile',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AlumniMainScreen(tabParam: 'profile'),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/alumni/:tab/chat/:conversationId',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId'];
          final studentName =
              state.uri.queryParameters['studentName'] ?? 'Student';

          return CustomTransitionPage(
            key: state.pageKey,
            child: ChatScreen(
              conversationId: conversationId!,
              studentName: studentName,
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/alumni/:tab/student_profile/:studentId',
        pageBuilder: (context, state) {
          final studentId = state.pathParameters['studentId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: StudentProfileScreen(studentId: studentId!),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/company',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const CompanyMainScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/content-creator',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ContentCreatorMainScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),

      // Content Creator Course Videos route
      GoRoute(
        path: '/course/:courseId/videos',
        pageBuilder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final courseTitle = extra?['courseTitle'] as String? ?? 'Course';

          return CustomTransitionPage(
            key: state.pageKey,
            child: CourseVideosScreen(
              courseId: courseId,
              courseTitle: courseTitle,
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),

      // Content Creator Go Live route
      GoRoute(
        path: '/content-creator/go-live',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final preselectedCourseId = extra?['courseId'] as String?;
          final preselectedCourseTitle = extra?['courseTitle'] as String?;

          return CustomTransitionPage(
            key: state.pageKey,
            child: GoLiveScreen(
              preselectedCourseId: preselectedCourseId,
              preselectedCourseTitle: preselectedCourseTitle,
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),

      // Content Creator Broadcast route
      GoRoute(
        path: '/content-creator/broadcast/:sessionId',
        pageBuilder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final liveSession = extra?['liveSession'] as LiveSession;

          return CustomTransitionPage(
            key: state.pageKey,
            child: BroadcastScreen(
              sessionId: sessionId,
              liveSession: liveSession,
            ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),

      // Content Creator Live Sessions route
      GoRoute(
        path: '/content-creator/live-sessions',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LiveSessionsScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),

      // Content Creator Schedule Live Session route
      GoRoute(
        path: '/content-creator/schedule-live',
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ScheduleLiveScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
                child: child,
              );
            },
          );
        },
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: Center(
            child: Text('No route defined for ${state.matchedLocation}'),
          ),
        ),
  );
});

// Helper function to build the pages
Widget _buildPage(GoRouterState state) {
  if (state.matchedLocation == '/login') {
    return const LoginScreen();
  } else if (state.matchedLocation == '/register') {
    return const RegisterScreen();
  } else if (state.matchedLocation.startsWith('/verify-email')) {
    final email = state.uri.queryParameters['email'] ?? '';
    return OtpVerificationScreen(email: email);
  } else if (state.matchedLocation == '/admin') {
    return const AdminMainScreen();
  } else if (state.matchedLocation == '/alumni') {
    return const AlumniMainScreen();
  } else if (state.matchedLocation == '/alumni/student_profile') {
    final args = state.extra as Map<String, dynamic>;
    final studentId = args['id'] as String;
    return StudentProfileScreen(studentId: studentId);
  } else if (state.matchedLocation == '/alumni/chat') {
    final args = state.extra as Map<String, dynamic>;
    final conversationId = args['conversationId'] as String;
    final studentName = args['studentName'] as String;
    return ChatScreen(conversationId: conversationId, studentName: studentName);
  } else if (state.matchedLocation == '/company') {
    return const CompanyMainScreen();
  } else if (state.matchedLocation == '/content-creator') {
    return const ContentCreatorMainScreen();
  } else if (state.matchedLocation.startsWith('/course/')) {
    final courseId = state.pathParameters['courseId'] ?? '';
    final extra = state.extra as Map<String, dynamic>?;
    final courseTitle = extra?['courseTitle'] as String? ?? 'Course';
    return CourseVideosScreen(courseId: courseId, courseTitle: courseTitle);
  } else if (state.matchedLocation == '/content-creator/go-live') {
    final extra = state.extra as Map<String, dynamic>?;
    final preselectedCourseId = extra?['courseId'] as String?;
    final preselectedCourseTitle = extra?['courseTitle'] as String?;
    return GoLiveScreen(
      preselectedCourseId: preselectedCourseId,
      preselectedCourseTitle: preselectedCourseTitle,
    );
  } else if (state.matchedLocation.startsWith('/content-creator/broadcast/')) {
    final sessionId = state.pathParameters['sessionId'] ?? '';
    final extra = state.extra as Map<String, dynamic>?;
    final liveSession = extra?['liveSession'] as LiveSession;
    return BroadcastScreen(sessionId: sessionId, liveSession: liveSession);
  } else if (state.matchedLocation == '/content-creator/live-sessions') {
    return const LiveSessionsScreen();
  } else if (state.matchedLocation == '/content-creator/schedule-live') {
    return const ScheduleLiveScreen();
  }

  // Error page
  return Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(child: Text('No route defined for ${state.matchedLocation}')),
  );
}
