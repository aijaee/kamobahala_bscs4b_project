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

      // Link user to any pending organization invites by email
      await _linkToPendingOrganizations(response.user!.id, email);

      return response;
    } catch (e) {
      if (_client.auth.currentUser != null) {
        await _client.auth.signOut();
      }
      rethrow;
    }
  }

  // Link a newly registered user to any pending organization_members entries that match their email
  Future<void> _linkToPendingOrganizations(String userId, String email) async {
    try {
      // Fetch user's full_name from profiles table
      final userProfile = await _client
          .from('profiles')
          .select('full_name')
          .eq('email', email)
          .maybeSingle();

      String? fullName = userProfile?['full_name'] as String?;

      // Update all organization_members entries with this email to link them to the user and set name
      await _client.from('organization_members').update({
        'user_id': userId,
        'name': fullName,
      }).eq('email', email);
    } catch (e) {
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
