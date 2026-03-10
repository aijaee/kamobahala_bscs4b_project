import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {

    _setLoading(true);
    _errorMessage = null;

    try {

      // TODO IMPLEMENT ACTUAL AUTH LOGIC

      // ============================================
      // BACKEND PLACEHOLDER
      // ============================================
      // Here is where Supabase authentication will happen
      //
      // Example later:
      // final response = await Supabase.instance.client.auth.signInWithPassword(
      //   email: email,
      //   password: password,
      // );
      //
      // if(response.user == null){
      //    throw Exception("Invalid login");
      // }
      // ============================================

      await Future.delayed(const Duration(seconds: 2));

      // Simulated login success
      _setLoading(false);
      return true;

    } catch (e) {

      _errorMessage = "Login failed";
      _setLoading(false);
      return false;

    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}