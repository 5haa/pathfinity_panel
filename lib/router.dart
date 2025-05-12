import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_panel/screens/auth/login_screen.dart';
import 'package:admin_panel/screens/auth/register_screen.dart';
import 'package:admin_panel/screens/auth/otp_verification_screen.dart';
import 'package:admin_panel/screens/admin/admin_dashboard.dart';
import 'package:admin_panel/screens/alumni/alumni_dashboard.dart';
import 'package:admin_panel/screens/alumni/students_list_screen.dart';
import 'package:admin_panel/screens/alumni/student_profile_screen.dart';
import 'package:admin_panel/screens/alumni/conversations_list_screen.dart';
import 'package:admin_panel/screens/alumni/chat_screen.dart';
import 'package:admin_panel/screens/company/company_dashboard.dart';
import 'package:admin_panel/screens/content_creator/content_creator_dashboard.dart';
import 'package:admin_panel/screens/content_creator/course_videos_screen.dart';
import 'package:admin_panel/screens/content_creator/go_live_screen.dart';
import 'package:admin_panel/screens/content_creator/broadcast_screen.dart';
import 'package:admin_panel/screens/content_creator/live_sessions_screen.dart';
import 'package:admin_panel/models/live_session_model.dart';
import 'package:admin_panel/providers/auth_provider.dart';
import 'package:admin_panel/services/auth_service.dart';

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

      debugPrint(
        'Router redirect - Current location: ${state.matchedLocation}, User logged in: $loggedIn',
      );

      // If not logged in and not on login, register, or verify-email page, redirect to login
      if (!loggedIn &&
          !isLoginRoute &&
          !isRegisterRoute &&
          !isVerifyEmailRoute) {
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
            return '/alumni';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),

      // Dashboard routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      // Alumni routes
      GoRoute(
        path: '/alumni',
        builder: (context, state) => const AlumniDashboard(),
      ),
      GoRoute(
        path: '/alumni/students',
        builder: (context, state) => const StudentsListScreen(),
      ),
      GoRoute(
        path: '/alumni/student_profile',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final studentId = args['id'] as String;
          return StudentProfileScreen(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/alumni/conversations',
        builder: (context, state) => const ConversationsListScreen(),
      ),
      GoRoute(
        path: '/alumni/chat',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          final conversationId = args['conversationId'] as String;
          final studentName = args['studentName'] as String;
          return ChatScreen(
            conversationId: conversationId,
            studentName: studentName,
          );
        },
      ),
      GoRoute(
        path: '/company',
        builder: (context, state) => const CompanyDashboard(),
      ),
      GoRoute(
        path: '/content-creator',
        builder: (context, state) => const ContentCreatorDashboard(),
      ),

      // Content Creator Course Videos route
      GoRoute(
        path: '/course/:courseId/videos',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final courseTitle = extra?['courseTitle'] as String? ?? 'Course';

          return CourseVideosScreen(
            courseId: courseId,
            courseTitle: courseTitle,
          );
        },
      ),

      // Content Creator Go Live route
      GoRoute(
        path: '/content-creator/go-live',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final preselectedCourseId = extra?['courseId'] as String?;
          final preselectedCourseTitle = extra?['courseTitle'] as String?;

          return GoLiveScreen(
            preselectedCourseId: preselectedCourseId,
            preselectedCourseTitle: preselectedCourseTitle,
          );
        },
      ),

      // Content Creator Broadcast route
      GoRoute(
        path: '/content-creator/broadcast/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final liveSession = extra?['liveSession'] as LiveSession;

          return BroadcastScreen(
            sessionId: sessionId,
            liveSession: liveSession,
          );
        },
      ),

      // Content Creator Live Sessions route
      GoRoute(
        path: '/content-creator/live-sessions',
        builder: (context, state) => const LiveSessionsScreen(),
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
