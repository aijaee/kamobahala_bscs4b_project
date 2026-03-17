import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    // Napoleon: Implemented live backend integration.
    // Handles Supabase password authentication
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _authService.login(email, password);

      if (response.user == null) {
        throw Exception("Invalid login credentials");
      }

      _setLoading(false);
      return true;
    } catch (e) {
      // Napoleon: Fixed registration flow and dynamic name sync.
      if (e is AuthException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString();
      }
      _setLoading(false);
      return false;
    }
  }

  // Handles user registration
  // Napoleon: Fixed atomic registration and database sync.
  Future<bool> register(String email, String password,
      {String? fullName}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Awaits the full registration and profile sync pipeline.
      // AuthService handles the all-or-nothing logic.
      await _authService.register(email, password, fullName: fullName);
      _setLoading(false);
      return true;
    } catch (e) {
      if (e is AuthException) {
        if (e.message.contains("already registered")) {
          _errorMessage = "A user with this email is already registered.";
        } else {
          _errorMessage = e.message;
        }
      } else {
        _errorMessage = e.toString();
      }
      _setLoading(false);
      return false;
    }
  }

  // Handles user logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
