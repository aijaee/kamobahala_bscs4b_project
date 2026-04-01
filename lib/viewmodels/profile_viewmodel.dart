import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/auth_service.dart';
import '../core/services/organization_service.dart';
import '../core/services/admin_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final OrganizationService _orgService = OrganizationService();
  final AdminService _adminService = AdminService();

  // User Profile Data
  String? _displayName;
  String? _email;
  String? _currentOrganizationId;
  String? _currentOrganizationName;
  String? _userRole;
  List<Map<String, dynamic>> _organizations = [];

  // Loading and Error States
  bool _isLoading = false;
  bool _isUpdatingName = false;
  String? _errorMessage;
  String? _successMessage;

  // Getters
  String? get displayName => _displayName;
  String? get email => _email;
  String? get currentOrganizationId => _currentOrganizationId;
  String? get currentOrganizationName => _currentOrganizationName;
  String? get userRole => _userRole;
  List<Map<String, dynamic>> get organizations => _organizations;
  bool get isLoading => _isLoading;
  bool get isUpdatingName => _isUpdatingName;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Initialize profile data with current organization context
  Future<void> initializeProfile(String organizationId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Parallelize all database calls for faster loading
      final results = await Future.wait([
        _authService.getUserProfile().then((profile) {
          if (profile != null) {
            _displayName = profile['full_name'] as String?;
            _email = profile['email'] as String?;
          }
          return null;
        }),
        _orgService.getOrganizations().then((orgs) {
          _organizations = orgs;
          return null;
        }),
        _adminService.getUserRoleInOrganization(organizationId),
      ]);

      // Set current organization data
      _currentOrganizationId = organizationId;
      
      // Find current organization name
      final currentOrg = _organizations.firstWhere(
        (org) => org['id'] == organizationId,
        orElse: () => {},
      );
      if (currentOrg.isNotEmpty) {
        _currentOrganizationName = currentOrg['name'] as String?;
      }

      // Set role from parallel results
      _userRole = results[2] as String?;

      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      _setLoading(false);
    }
  }

  /// Update user's display name
  Future<bool> updateDisplayName(String newName) async {
    if (newName.isEmpty) {
      _errorMessage = 'Display name cannot be empty';
      notifyListeners();
      return false;
    }

    _setUpdatingName(true);
    _errorMessage = null;
    _successMessage = null;

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Update the profiles table
      await Supabase.instance.client.from('profiles').update({
        'full_name': newName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // Update local state
      _displayName = newName;
      _successMessage = 'Display name updated successfully';
      _setUpdatingName(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update display name: $e';
      _setUpdatingName(false);
      return false;
    }
  }

  /// Switch to a different organization
  Future<bool> switchOrganization(String organizationId) async {
    try {
      // Reinitialize with new organization ID
      await initializeProfile(organizationId);
      _successMessage = 'Switched to organization successfully';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to switch organization: $e';
      return false;
    }
  }

  /// Logout user
  Future<bool> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setUpdatingName(bool value) {
    _isUpdatingName = value;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
