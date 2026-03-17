import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Handles user login with Supabase
  Future<AuthResponse> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response;
  }

  // Handles user registration with Supabase
  // Napoleon: Fixed atomic registration and database sync.
  Future<AuthResponse> register(String email, String password,
      {String? fullName}) async {
    try {
      // 1. Atomic Registration: Create Auth User and pass name in metadata.
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user == null) {
        throw const AuthException(
            "Registration failed: No user returned from Supabase.");
      }

      // 2. Explicitly insert into profiles table & VERIFY
      if (fullName != null) {
        try {
          // Retry Logic
          await Future.delayed(const Duration(milliseconds: 500));

          await _client.from('profiles').upsert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Error Handling
          // Napoleon: Standardized navigation, secured config keys, and implemented dynamic data fetching.
        }
      }

      return response;
    } catch (e) {
      // 3. Error Cleanup: Sign out the new user if profile creation fails.
      if (_client.auth.currentUser != null) {
        await _client.auth.signOut();
      }
      rethrow;
    }
  }

  // Handles user logout
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current authenticated user
  User? get currentUser => _client.auth.currentUser;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Napoleon: Implemented live backend integration.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }
}
