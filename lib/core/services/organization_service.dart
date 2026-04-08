import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/organization.dart';
import '../../models/organization_member.dart';

class OrganizationService {
  final SupabaseClient _client = Supabase.instance.client;

  // TODO: [MVVM] this should be called via OrganizationViewModel for UI data binding
  Future<List<Organization>> getOrganizations() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];
      final response = await _client
          .from('organization_members')
          .select('organization_id')
          .or('user_id.eq.${user.id},email.eq.${user.email}');

      if (response.isEmpty) return [];
      final orgIds = <String>{};
      for (final m in response) {
        orgIds.add(m['organization_id'] as String);
      }
      final organizations = await _client
          .from('organizations')
          .select()
          .inFilter('id', orgIds.toList());

      return (organizations as List)
          .map((o) => Organization.fromMap(o as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching organizations: $e');
      return [];
    }
  }

  Future<Organization> createOrganization(
      Map<String, dynamic> data) async {
    try {
      final newOrg = await _client.from('organizations').insert(data).select().single();
      final organization = Organization.fromMap(newOrg);
      
      final user = _client.auth.currentUser;
      if (user != null && newOrg['id'] != null) {
        String? creatorFullName;
        try {
          final creatorProfile = await _client
              .from('profiles')
              .select('full_name')
              .eq('email', user.email!)
              .maybeSingle();
          creatorFullName = creatorProfile?['full_name'] as String?;
        } catch (e) {
          print('Error fetching creator profile: $e');
        }

        await _client.from('organization_members').insert({
          'organization_id': newOrg['id'],
          'user_id': user.id,
          'email': user.email,
          'name': creatorFullName,
          'role': 'Admin',
        });
      }
      
      return organization;
    } catch (e) {
      print('Error creating organization: $e');
      rethrow;
    }
  }

  Future<Organization> updateOrganization(
      String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('organizations')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Organization.fromMap(response);
  }

  Future<void> deleteOrganization(String id) async {
    await _client.from('organizations').delete().eq('id', id);
  }

  Future<List<OrganizationMember>> getOrganizationMembers(String organizationId) async {
    try {
      final response = await _client
          .from('organization_members')
          .select()
          .eq('organization_id', organizationId);
      
      return (response as List)
          .map((m) => OrganizationMember.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching organization members: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTaskCategories(String organizationId) async {
    try {
      final response = await _client
          .from('task_categories')
          .select()
          .eq('organization_id', organizationId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching task categories: $e');
      // Don't fall back to hardcoded list - return empty list or throw
      // This way users will see an error and know something went wrong
      // rather than losing their custom categories
      return [];
    }
  }

  Future<Map<String, dynamic>?> createTaskCategory(String organizationId, String categoryName) async {
    try {
      final response = await _client
          .from('task_categories')
          .insert({
            'organization_id': organizationId,
            'name': categoryName,
          })
          .select();
      
      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      print('Error creating task category: $e');
      return null;
    }
  }

  Future<void> syncMemberNamesFromProfiles(String organizationId) async {
    try {
      final members = await _client
          .from('organization_members')
          .select()
          .eq('organization_id', organizationId);
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
            print('Error syncing member $email: $e');
          }
        }
      }

      print('Synced member names for organization $organizationId');
    } catch (e) {
      print('Error syncing member names: $e');
    }
  }
}

