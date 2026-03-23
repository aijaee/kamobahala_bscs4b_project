import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get current user's role in an organization
  Future<String?> getUserRoleInOrganization(String organizationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('organization_members')
          .select('role')
          .eq('organization_id', organizationId)
          .eq('user_id', userId)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      print('Error checking admin role: $e');
      return null;
    }
  }

  /// Check if user is admin in organization
  Future<bool> isUserAdmin(String organizationId) async {
    final role = await getUserRoleInOrganization(organizationId);
    return role == 'Admin' || role == 'admin';
  }

  /// Get all members in an organization
  Future<List<Map<String, dynamic>>> getOrganizationMembers(String organizationId) async {
    try {
      final response = await _client
          .from('organization_members')
          .select()
          .eq('organization_id', organizationId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching members: $e');
      return [];
    }
  }

  /// Update user role in organization
  Future<bool> updateUserRole(String organizationId, String userId, String newRole) async {
    try {
      await _client
          .from('organization_members')
          .update({'role': newRole})
          .eq('organization_id', organizationId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error updating role: $e');
      return false;
    }
  }
}
