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
      debugPrint(
        'Starting user signup process for email: $email and user type: $userType',
      );

      // Add user type to metadata
      final String userTypeString = _getUserTypeString(userType);
      debugPrint('User type string: $userTypeString');

      // Create user in auth
      debugPrint('Creating auth user with email: $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'p_user_type': 'user_' + userTypeString, ...userData},
      );

      debugPrint('Auth user creation response: ${response.user?.id}');

      // If user is created successfully, add user data to the appropriate table
      if (response.user != null) {
        debugPrint('Auth user created successfully. Creating user profile...');
        try {
          await _createUserProfile(response.user!.id, userType, userData);
          debugPrint('User profile created successfully');
        } catch (profileError) {
          debugPrint('Error creating user profile: $profileError');
          // We could add cleanup here if needed
          rethrow;
        }
      } else {
        debugPrint(
          'Auth user creation failed with no error: ${response.session}, ${response.user}',
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error during signup process: $e');
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

  // Send password reset OTP code
  Future<void> sendPasswordResetOTP(String email) async {
    try {
      debugPrint('AuthService: Sending password reset OTP for email: $email');

      await _supabase.auth.resetPasswordForEmail(email, redirectTo: null);

      debugPrint('AuthService: Password reset OTP sent successfully');
    } catch (e) {
      debugPrint('AuthService: Error sending password reset OTP: $e');
      rethrow;
    }
  }

  // Verify OTP code for password reset
  Future<bool> verifyPasswordResetOTP(String email, String otp) async {
    try {
      debugPrint('AuthService: Verifying password reset OTP for email: $email');

      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      debugPrint(
        'AuthService: Password reset OTP verification response - User: ${response.user?.id}',
      );

      return response.user != null;
    } catch (e) {
      debugPrint('AuthService: Error verifying password reset OTP: $e');
      rethrow;
    }
  }

  // Reset password with OTP
  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      debugPrint('AuthService: Resetting password for email: $email');

      // First verify the OTP if not already verified
      final verifyResponse = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.recovery,
      );

      // If verification succeeded, update the password
      if (verifyResponse.user != null) {
        await _supabase.auth.updateUser(UserAttributes(password: newPassword));

        debugPrint('AuthService: Password reset successful');
      } else {
        throw Exception('Invalid OTP verification');
      }
    } catch (e) {
      debugPrint('AuthService: Error resetting password: $e');
      rethrow;
    }
  }

  // Verify OTP code
  Future<bool> verifyOTP(String email, String otp) async {
    try {
      debugPrint('AuthService: Verifying OTP for email: $email');

      // First, try to verify the OTP
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      debugPrint(
        'AuthService: OTP verification response - User: ${response.user?.id}, email confirmed: ${response.user?.emailConfirmedAt}',
      );

      // If we have a user but verification didn't mark the email as confirmed,
      // we may need to refresh the session or try a different approach
      if (response.user != null) {
        // First attempt: refresh the session
        debugPrint(
          'AuthService: Attempting to refresh session after OTP verification',
        );
        try {
          final refreshResult = await _supabase.auth.refreshSession();
          debugPrint(
            'AuthService: Session refreshed. User: ${refreshResult.user?.id}, Email confirmed: ${refreshResult.user?.emailConfirmedAt}',
          );

          // If refreshing worked and email is now confirmed, return success
          if (refreshResult.user?.emailConfirmedAt != null) {
            return true;
          }
        } catch (refreshError) {
          debugPrint('AuthService: Error refreshing session: $refreshError');
        }

        // If we still don't have confirmation, try a deeper check
        final isVerified = await isEmailVerified();
        debugPrint(
          'AuthService: Deep email verification check result: $isVerified',
        );
        return isVerified;
      }

      // Fall back to checking if we have a user as a success indicator
      return response.user != null;
    } catch (e) {
      debugPrint('AuthService: Error verifying OTP: $e');

      // Special handling for specific error messages that might still mean success
      if (e.toString().contains('User already confirmed')) {
        debugPrint(
          'AuthService: User is already confirmed, treating as success',
        );
        return true;
      }

      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      if (currentUser == null) return false;

      debugPrint(
        'Checking email verification status for user: ${currentUser?.id}',
      );
      debugPrint(
        'Current email confirmed at: ${currentUser?.emailConfirmedAt}',
      );

      // Refresh the session to get the latest user data
      try {
        final refreshResult = await _supabase.auth.refreshSession();
        debugPrint(
          'Session refreshed successfully. User: ${refreshResult.user?.id}',
        );
        debugPrint(
          'Refreshed email confirmed at: ${refreshResult.user?.emailConfirmedAt}',
        );
      } catch (refreshError) {
        debugPrint(
          'Error refreshing session during email verification check: $refreshError',
        );
      }

      // Get the current user again to have the most updated info
      final updatedUser = _supabase.auth.currentUser;
      debugPrint(
        'Updated email confirmed at: ${updatedUser?.emailConfirmedAt}',
      );

      // Check if email is confirmed
      return updatedUser?.emailConfirmedAt != null;
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
      debugPrint(
        'Creating user profile for userId: $userId with type: $userType',
      );
      debugPrint('User data: $userData');

      switch (userType) {
        case UserType.alumni:
          try {
            // Check if profile already exists to prevent 409 conflict
            debugPrint('Checking if alumni profile exists for userId: $userId');
            final existing =
                await _supabase
                    .from('user_alumni')
                    .select('id')
                    .eq('id', userId)
                    .maybeSingle();

            debugPrint('Existing alumni check result: $existing');

            // Only insert if no record exists
            if (existing == null) {
              debugPrint(
                'No existing alumni record found. Creating new record...',
              );
              final insertData = {
                'id': userId,
                'first_name': userData['first_name'],
                'last_name': userData['last_name'],
                'email': userData['email'],
                'birthdate': userData['birthdate'],
                'graduation_year': userData['graduation_year'],
                'university': userData['university'],
                'experience': userData['experience'],
              };

              debugPrint('Alumni insert data: $insertData');

              await _supabase.from('user_alumni').insert(insertData);
              debugPrint('Alumni profile created successfully');
            } else {
              // Profile already exists, update it instead
              debugPrint('Existing alumni record found. Updating record...');
              await _supabase
                  .from('user_alumni')
                  .update({
                    'first_name': userData['first_name'],
                    'last_name': userData['last_name'],
                    'email': userData['email'],
                    'birthdate': userData['birthdate'],
                    'graduation_year': userData['graduation_year'],
                    'university': userData['university'],
                    'experience': userData['experience'],
                  })
                  .eq('id', userId);
              debugPrint('Alumni profile updated successfully');
            }
          } catch (alumniError) {
            debugPrint('Error in alumni profile creation: $alumniError');
            rethrow;
          }
          break;

        case UserType.company:
          try {
            // Check if profile already exists to prevent 409 conflict
            debugPrint(
              'Checking if company profile exists for userId: $userId',
            );
            final existingCompany =
                await _supabase
                    .from('user_companies')
                    .select('id')
                    .eq('id', userId)
                    .maybeSingle();

            debugPrint('Existing company check result: $existingCompany');

            // Only insert if no record exists
            if (existingCompany == null) {
              debugPrint(
                'No existing company record found. Creating new record...',
              );
              final insertData = {
                'id': userId,
                'company_name': userData['company_name'],
                'email': userData['email'],
              };

              debugPrint('Company insert data: $insertData');

              await _supabase.from('user_companies').insert(insertData);
              debugPrint('Company profile created successfully');
            } else {
              // Profile already exists, update it instead
              debugPrint('Existing company record found. Updating record...');
              await _supabase
                  .from('user_companies')
                  .update({
                    'company_name': userData['company_name'],
                    'email': userData['email'],
                  })
                  .eq('id', userId);
              debugPrint('Company profile updated successfully');
            }
          } catch (companyError) {
            debugPrint('Error in company profile creation: $companyError');
            rethrow;
          }
          break;

        case UserType.contentCreator:
          try {
            // Check if profile already exists to prevent 409 conflict
            debugPrint(
              'Checking if content creator profile exists for userId: $userId',
            );
            final existingCreator =
                await _supabase
                    .from('user_content_creators')
                    .select('id')
                    .eq('id', userId)
                    .maybeSingle();

            debugPrint(
              'Existing content creator check result: $existingCreator',
            );

            // Only insert if no record exists
            if (existingCreator == null) {
              debugPrint(
                'No existing content creator record found. Creating new record...',
              );
              final insertData = {
                'id': userId,
                'first_name': userData['first_name'],
                'last_name': userData['last_name'],
                'email': userData['email'],
                'birthdate': userData['birthdate'],
                'bio': userData['bio'],
                'phone': userData['phone'],
              };

              debugPrint('Content creator insert data: $insertData');

              await _supabase.from('user_content_creators').insert(insertData);
              debugPrint('Content creator profile created successfully');
            } else {
              // Profile already exists, update it instead
              debugPrint(
                'Existing content creator record found. Updating record...',
              );
              await _supabase
                  .from('user_content_creators')
                  .update({
                    'first_name': userData['first_name'],
                    'last_name': userData['last_name'],
                    'email': userData['email'],
                    'birthdate': userData['birthdate'],
                    'bio': userData['bio'],
                    'phone': userData['phone'],
                  })
                  .eq('id', userId);
              debugPrint('Content creator profile updated successfully');
            }
          } catch (creatorError) {
            debugPrint(
              'Error in content creator profile creation: $creatorError',
            );
            rethrow;
          }
          break;

        default:
          debugPrint('Unknown user type: $userType');
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
        return 'admin';
      case UserType.alumni:
        return 'alumni';
      case UserType.company:
        return 'company';
      case UserType.contentCreator:
        return 'content_creator';
      default:
        return 'alumni'; // Default fallback
    }
  }

  // Check if a user with a given email already exists
  Future<bool> checkExistingUser(String email) async {
    try {
      debugPrint('Checking if user exists with email: $email');
      final response = await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      // If OTP email is sent successfully, the user exists
      debugPrint('User exists check response: OTP sent successfully');

      return true; // User exists if we get here
    } catch (e) {
      if (e.toString().contains('Email not confirmed')) {
        // Email exists but not confirmed
        return true;
      } else if (e.toString().contains('Invalid login credentials')) {
        // User doesn't exist
        return false;
      }
      // For any other error, assume the user might exist
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

  // Diagnose RLS policy issues
  Future<Map<String, bool>> diagnosePolicyIssues() async {
    Map<String, bool> results = {
      'user_alumni': false,
      'user_companies': false,
      'user_content_creators': false,
    };

    try {
      // Test if we can read tables (any access would mean RLS is likely not the culprit)
      try {
        await _supabase.from('user_alumni').select('id').limit(1);
        results['user_alumni'] = true;
      } catch (e) {
        debugPrint('Alumni table access check failed: $e');
      }

      try {
        await _supabase.from('user_companies').select('id').limit(1);
        results['user_companies'] = true;
      } catch (e) {
        debugPrint('Companies table access check failed: $e');
      }

      try {
        await _supabase.from('user_content_creators').select('id').limit(1);
        results['user_content_creators'] = true;
      } catch (e) {
        debugPrint('Content creators table access check failed: $e');
      }

      return results;
    } catch (e) {
      debugPrint('Error diagnosing policy issues: $e');
      return results;
    }
  }
}
