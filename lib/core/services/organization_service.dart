import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationService {
  final SupabaseClient _client = Supabase.instance.client;

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
}
