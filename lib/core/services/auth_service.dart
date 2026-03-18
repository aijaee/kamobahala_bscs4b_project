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
  Future<AuthResponse> register(String email, String password,
      {String? fullName}) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user == null) {
        throw const AuthException(
            "Registration failed: No user returned from Supabase.");
      }

      if (fullName != null) {
        try {
          await Future.delayed(const Duration(milliseconds: 500));

          await _client.from('profiles').upsert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          // Silently handle profile creation errors
        }
      }

      return response;
    } catch (e) {
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
