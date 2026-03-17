import 'package:supabase_flutter/supabase_flutter.dart';

class DepositoryService {
  final SupabaseClient _client = Supabase.instance.client;

  // TODO: [MVVM] move this data layer into RepositoryViewModel or DepositoryViewModel
  // Fetches all repositories
  Future<List<Map<String, dynamic>>> getRepositories() async {
    return await _client.from('repositories').select();
  }

  // Creates a new repository configuration
  Future<Map<String, dynamic>> createRepository(
      Map<String, dynamic> data) async {
    return await _client.from('repositories').insert(data).select().single();
  }

  // Updates an existing repository configuration
  Future<Map<String, dynamic>> updateRepository(
      String id, Map<String, dynamic> data) async {
    return await _client
        .from('repositories')
        .update(data)
        .eq('id', id)
        .select()
        .single();
  }

  // Deletes a repository configuration
  Future<void> deleteRepository(String id) async {
    await _client.from('repositories').delete().eq('id', id);
  }
}
