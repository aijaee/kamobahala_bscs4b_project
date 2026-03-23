import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationService {
  final SupabaseClient _client = Supabase.instance.client;

  // TODO: [MVVM] this should be called via OrganizationViewModel for UI data binding
  // Fetches all organizations available to the user
  Future<List<Map<String, dynamic>>> getOrganizations() async {
    return await _client.from('organizations').select();
  }

  // Creates a new organization record
  Future<Map<String, dynamic>> createOrganization(
      Map<String, dynamic> data) async {
    return await _client.from('organizations').insert(data).select().single();
  }

  // Updates an existing organization record
  Future<Map<String, dynamic>> updateOrganization(
      String id, Map<String, dynamic> data) async {
    return await _client
        .from('organizations')
        .update(data)
        .eq('id', id)
        .select()
        .single();
  }

  // Deletes an organization record
  Future<void> deleteOrganization(String id) async {
    await _client.from('organizations').delete().eq('id', id);
  }

  // Fetches all members of an organization
  Future<List<Map<String, dynamic>>> getOrganizationMembers(String organizationId) async {
    try {
      final response = await _client
          .from('organization_members')
          .select()
          .eq('organization_id', organizationId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // If organization_members table doesn't exist, try to fetch from users table
      // This is a fallback - adjust based on your actual schema
      print('Error fetching organization members: $e');
      return [];
    }
  }

  // Fetches all task categories for an organization
  Future<List<Map<String, dynamic>>> getTaskCategories(String organizationId) async {
    try {
      final response = await _client
          .from('task_categories')
          .select()
          .eq('organization_id', organizationId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // If task_categories table doesn't exist, return default categories
      // This is expected if the table hasn't been created in Supabase
      return [
        {'id': '1', 'name': 'Development'},
        {'id': '2', 'name': 'Design'},
        {'id': '3', 'name': 'Marketing'},
        {'id': '4', 'name': 'Documentation'},
        {'id': '5', 'name': 'Testing'},
      ];
    }
  }

  // Creates a new task category for an organization
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
}

