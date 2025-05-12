import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_panel/config/supabase_config.dart';
import 'package:admin_panel/models/admin_model.dart';
import 'package:admin_panel/models/alumni_model.dart';
import 'package:admin_panel/models/company_model.dart';
import 'package:admin_panel/models/content_creator_model.dart';

enum UserType { admin, alumni, company, contentCreator, unknown }

class UserTypeInfo {
  final UserType userType;
  final bool isApproved;
  final bool isSuperAdmin;

  UserTypeInfo({
    required this.userType,
    required this.isApproved,
    required this.isSuperAdmin,
  });
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  }

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Attempting to sign in: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint(
        'AuthService: Sign in successful for user: ${response.user?.id}',
      );
      return response;
    } catch (e) {
      debugPrint('AuthService: Error signing in: $e');

      // Re-throw the error so it can be handled by the caller
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required UserType userType,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Add user type to metadata
      final String userTypeString = _getUserTypeString(userType);

      // Create user in auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'p_user_type': userTypeString, ...userData},
      );

      // If user is created successfully, add user data to the appropriate table
      if (response.user != null) {
        await _createUserProfile(response.user!.id, userType, userData);
      }

      return response;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Send email verification OTP
  Future<void> sendEmailVerification(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
        shouldCreateUser: false,
      );
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      rethrow;
    }
  }

  // Verify OTP code
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      debugPrint('AuthService: Verifying OTP for email: $email');

      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      debugPrint(
        'AuthService: OTP verification response - User: ${response.user?.id}',
      );

      // Explicitly refresh the session after verification
      if (response.user != null) {
        try {
          final refreshResult = await _supabase.auth.refreshSession();
          debugPrint(
            'AuthService: Session refreshed. User: ${refreshResult.user?.id}',
          );
        } catch (refreshError) {
          debugPrint('AuthService: Error refreshing session: $refreshError');
        }
      }

      return response.user != null;
    } catch (e) {
      debugPrint('AuthService: Error verifying OTP: $e');
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      if (currentUser == null) return false;

      // Refresh the session to get the latest user data
      await _supabase.auth.refreshSession();

      // Check if email is confirmed
      return currentUser?.emailConfirmedAt != null;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  // Get user type and approval status
  Future<UserTypeInfo> getUserTypeAndStatus() async {
    try {
      if (currentUser == null) {
        return UserTypeInfo(
          userType: UserType.unknown,
          isApproved: false,
          isSuperAdmin: false,
        );
      }

      final response =
          await _supabase.rpc('get_user_type_and_status').select().single();

      final userTypeStr = response['user_type'] as String?;
      final isApproved = response['is_approved'] as bool? ?? false;
      final isSuperAdmin = response['is_super_admin'] as bool? ?? false;

      return UserTypeInfo(
        userType: _parseUserType(userTypeStr),
        isApproved: isApproved,
        isSuperAdmin: isSuperAdmin,
      );
    } catch (e) {
      debugPrint('Error getting user type: $e');
      return UserTypeInfo(
        userType: UserType.unknown,
        isApproved: false,
        isSuperAdmin: false,
      );
    }
  }

  // Get user profile based on user type
  Future<dynamic> getUserProfile() async {
    try {
      if (currentUser == null) {
        return null;
      }

      final userTypeInfo = await getUserTypeAndStatus();
      final userId = currentUser!.id;

      switch (userTypeInfo.userType) {
        case UserType.admin:
          final data =
              await _supabase
                  .from('user_admins')
                  .select()
                  .eq('id', userId)
                  .single();
          return AdminUser.fromJson(data);

        case UserType.alumni:
          final data =
              await _supabase
                  .from('user_alumni')
                  .select()
                  .eq('id', userId)
                  .single();
          return AlumniUser.fromJson(data);

        case UserType.company:
          final data =
              await _supabase
                  .from('user_companies')
                  .select()
                  .eq('id', userId)
                  .single();
          return CompanyUser.fromJson(data);

        case UserType.contentCreator:
          final data =
              await _supabase
                  .from('user_content_creators')
                  .select()
                  .eq('id', userId)
                  .single();
          return ContentCreatorUser.fromJson(data);

        case UserType.unknown:
          return null;
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Helper method to create user profile in the appropriate table
  Future<void> _createUserProfile(
    String userId,
    UserType userType,
    Map<String, dynamic> userData,
  ) async {
    try {
      switch (userType) {
        case UserType.alumni:
          await _supabase.from('user_alumni').insert({
            'id': userId,
            'first_name': userData['first_name'],
            'last_name': userData['last_name'],
            'email': userData['email'],
            'birthdate': userData['birthdate'],
            'graduation_year': userData['graduation_year'],
            'university': userData['university'],
            'experience': userData['experience'],
          });
          break;

        case UserType.company:
          await _supabase.from('user_companies').insert({
            'id': userId,
            'company_name': userData['company_name'],
            'email': userData['email'],
          });
          break;

        case UserType.contentCreator:
          await _supabase.from('user_content_creators').insert({
            'id': userId,
            'first_name': userData['first_name'],
            'last_name': userData['last_name'],
            'email': userData['email'],
            'birthdate': userData['birthdate'],
            'bio': userData['bio'],
            'phone': userData['phone'],
          });
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      // If profile creation fails, attempt to delete the auth user
      try {
        // This would typically be done server-side with a trigger
        // For client-side, we'd need admin privileges
        debugPrint(
          'User profile creation failed. User auth record may need manual cleanup.',
        );
      } catch (_) {}
      rethrow;
    }
  }

  // Helper method to parse user type from string
  UserType _parseUserType(String? userTypeStr) {
    switch (userTypeStr) {
      case 'admin':
        return UserType.admin;
      case 'alumni':
        return UserType.alumni;
      case 'company':
        return UserType.company;
      case 'content_creator':
        return UserType.contentCreator;
      default:
        return UserType.unknown;
    }
  }

  // Helper method to convert UserType to string
  String _getUserTypeString(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'user_admin';
      case UserType.alumni:
        return 'user_alumni';
      case UserType.company:
        return 'user_company';
      case UserType.contentCreator:
        return 'user_content_creator';
      default:
        return 'user_student'; // Default fallback
    }
  }
}
