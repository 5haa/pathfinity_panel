import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/services/auth_service.dart';

// Define the application authentication state
class AppAuthState {
  final User? user;
  final UserTypeInfo? userTypeInfo;
  final bool isLoading;
  final String? errorMessage;

  const AppAuthState({
    this.user,
    this.userTypeInfo,
    this.isLoading = false,
    this.errorMessage,
  });

  // Create a copy of the current state with some properties changed
  AppAuthState copyWith({
    User? user,
    UserTypeInfo? userTypeInfo,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppAuthState(
      user: user ?? this.user,
      userTypeInfo: userTypeInfo ?? this.userTypeInfo,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Clear the error message
  AppAuthState clearError() {
    return AppAuthState(
      user: user,
      userTypeInfo: userTypeInfo,
      isLoading: isLoading,
      errorMessage: null,
    );
  }
}

// Create a StateNotifier to manage the authentication state
class AuthNotifier extends StateNotifier<AppAuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AppAuthState()) {
    // Initialize the state with the current user
    _initializeAuthState();

    // Listen for auth state changes from Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _handleAuthChange(data.event, data.session);
    });
  }

  // Initialize the auth state with the current user
  Future<void> _initializeAuthState() async {
    final user = _authService.currentUser;

    if (user != null) {
      final userTypeInfo = await _authService.getUserTypeAndStatus();
      state = state.copyWith(user: user, userTypeInfo: userTypeInfo);
    }
  }

  // Handle authentication state changes from Supabase
  void _handleAuthChange(AuthChangeEvent event, Session? session) {
    if (session != null) {
      // User signed in
      _authService.getUserTypeAndStatus().then((userTypeInfo) {
        state = state.copyWith(user: session.user, userTypeInfo: userTypeInfo);
      });
    } else {
      // User signed out
      state = const AppAuthState();
    }
  }

  // Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      debugPrint('AuthNotifier: Attempting to sign in with email: $email');

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      final userTypeInfo = await _authService.getUserTypeAndStatus();
      debugPrint('AuthNotifier: Signed in user type: ${userTypeInfo.userType}');

      state = state.copyWith(
        user: response.user,
        userTypeInfo: userTypeInfo,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('AuthNotifier: Error signing in: $e');

      // Check if this is an email confirmation error
      if (e is AuthException &&
          (e.message.contains('Email not confirmed') ||
              e.message.contains('Email hasn\'t been confirmed'))) {
        debugPrint('AuthNotifier: Detected unconfirmed email error');
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e is AuthException
                ? e.message
                : 'An error occurred during login. Please try again.',
      );
      rethrow;
    }
  }

  // Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required UserType userType,
    required Map<String, dynamic> userData,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _authService.signUp(
        email: email,
        password: password,
        userType: userType,
        userData: userData,
      );

      final userTypeInfo = await _authService.getUserTypeAndStatus();

      state = state.copyWith(
        user: response.user,
        userTypeInfo: userTypeInfo,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error signing up: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e is AuthException
                ? e.message
                : 'An error occurred during registration. Please try again.',
      );
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _authService.signOut();
      state = const AppAuthState();
    } catch (e) {
      debugPrint('Error signing out: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred during sign out. Please try again.',
      );
      rethrow;
    }
  }

  // Refresh user type and status
  Future<void> refreshUserTypeAndStatus() async {
    if (state.user != null) {
      final userTypeInfo = await _authService.getUserTypeAndStatus();
      state = state.copyWith(userTypeInfo: userTypeInfo);
    }
  }

  // Send email verification OTP
  Future<void> sendEmailVerification(String email) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _authService.sendEmailVerification(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e is AuthException
                ? e.message
                : 'Failed to send verification email. Please try again.',
      );
      rethrow;
    }
  }

  // Send password reset OTP
  Future<void> sendPasswordResetOTP(String email) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _authService.sendPasswordResetOTP(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('AuthNotifier: Error sending password reset OTP: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e is AuthException
                ? e.message
                : 'Failed to send password reset code. Please try again.',
      );
      rethrow;
    }
  }

  // Verify password reset OTP
  Future<bool> verifyPasswordResetOTP(String email, String otp) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final result = await _authService.verifyPasswordResetOTP(email, otp);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      debugPrint('AuthNotifier: Error verifying password reset OTP: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e is AuthException
                ? e.message
                : 'Failed to verify reset code. Please try again.',
      );
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _authService.resetPassword(email, otp, newPassword);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('AuthNotifier: Error resetting password: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e is AuthException
                ? e.message
                : 'Failed to reset password. Please try again.',
      );
      rethrow;
    }
  }

  // Verify OTP code
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      debugPrint('AuthNotifier: Verifying OTP for email: $email');

      final result = await _authService.verifyOTP(email, otp);
      debugPrint('AuthNotifier: OTP verification result: $result');

      if (result) {
        // Refresh user type and status after successful verification
        debugPrint(
          'AuthNotifier: Refreshing user info after successful verification',
        );
        await refreshUserTypeAndStatus();

        // Double-check that we have the user info after verification
        final user = _authService.currentUser;
        final userTypeInfo = await _authService.getUserTypeAndStatus();

        debugPrint(
          'AuthNotifier: After verification - User: ${user?.id}, UserType: ${userTypeInfo.userType}',
        );

        state = state.copyWith(
          user: user,
          userTypeInfo: userTypeInfo,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return result;
    } catch (e) {
      debugPrint('AuthNotifier: Error verifying OTP: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage:
            e is AuthException
                ? e.message
                : 'Failed to verify OTP. Please try again.',
      );
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    return await _authService.isEmailVerified();
  }
}

// Global provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Global provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Convenience providers for auth state
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final userTypeInfoProvider = Provider<UserTypeInfo?>((ref) {
  return ref.watch(authProvider).userTypeInfo;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});
