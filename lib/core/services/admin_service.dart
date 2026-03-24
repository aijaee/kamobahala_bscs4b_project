import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get current user's role in an organization
  Future<String?> getUserRoleInOrganization(String organizationId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      // Try by user_id first
      var response = await _client
          .from('organization_members')
          .select('role')
          .eq('organization_id', organizationId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        final role = response['role'] as String?;
        return role;
      }

      // Fallback: try by email
      if (user.email != null) {
        response = await _client
            .from('organization_members')
            .select('role')
            .eq('organization_id', organizationId)
            .eq('email', user.email!)
            .maybeSingle();

        final role = response?['role'] as String?;
        return role;
      }
      
      return null;
    } catch (e) {
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
      // Fetch organization members with their name/full_name data already populated
      final response = await _client
          .from('organization_members')
          .select()
          .eq('organization_id', organizationId);
      
      // Normalize 'name' to 'full_name' for consistent UI display
      List<Map<String, dynamic>> members = [];
      for (var member in response) {
        final memberMap = Map<String, dynamic>.from(member);
        if (memberMap['name'] != null && memberMap['full_name'] == null) {
          memberMap['full_name'] = memberMap['name'];
        }
        members.add(memberMap);
      }
      
      return members;
    } catch (e) {
      return [];
    }
  }

  /// Update user role in organization
  Future<bool> updateUserRole(String organizationId, String emailOrUserId, String newRole) async {
    try {
      await _client
          .from('organization_members')
          .update({'role': newRole})
          .eq('organization_id', organizationId)
          .eq('email', emailOrUserId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add a new member to an organization by email
  Future<bool> addMemberByEmail(String organizationId, String email, String role) async {
    try {
      // First, fetch the full profile data from the profiles table
      final userProfile = await _client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      String? userId = userProfile?['id'] as String?;
      String? fullName = userProfile?['full_name'] as String?;

      // Insert with user_id if found, otherwise just with email
      if (userId != null) {
        await _client.from('organization_members').insert({
          'organization_id': organizationId,
          'user_id': userId,
          'email': email,
          'name': fullName,
          'role': role,
        });
      } else {
        // If user not found yet, still insert invitation with email for later linking
        await _client.from('organization_members').insert({
          'organization_id': organizationId,
          'email': email,
          'name': fullName,
          'role': role,
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove a member from an organization
  Future<bool> removeMember(String organizationId, String email) async {
    try {
      await _client
          .from('organization_members')
          .delete()
          .eq('organization_id', organizationId)
          .eq('email', email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Syncs/populates member names from profiles table for all members in an organization
  /// This is useful for updating existing members that have NULL names
  Future<void> syncMemberNamesFromProfiles(String organizationId) async {
    try {
      // Fetch all members
      final members = await _client
          .from('organization_members')
          .select()
          .eq('organization_id', organizationId);

      // For each member, fetch their profile and update their name
      for (var member in members) {
        final email = member['email'];
        if (email != null) {
          try {
            // Fetch profile by email
            final profile = await _client
                .from('profiles')
                .select('full_name, id')
                .eq('email', email)
                .maybeSingle();

            if (profile != null) {
              final fullName = profile['full_name'];
              final userId = profile['id'];

              // Update the organization_member with the profile data
              await _client
                  .from('organization_members')
                  .update({
                    'name': fullName,
                    'user_id': userId,
                  })
                  .eq('id', member['id']);
            }
          } catch (e) {
            // Continue syncing other members
          }
        }
      }
    } catch (e) {
      // Sync failed
    }
  }
}
