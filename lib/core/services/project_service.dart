import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;

  // TODO: [MVVM] this should be invoked by ProjectsViewModel and data injected into UI by Provider
  // Fetches projects for an organization
  Future<List<Map<String, dynamic>>> fetchProjects(String orgId) async {
    final response =
        await _client.from('projects').select().eq('organization_id', orgId);

    return List<Map<String, dynamic>>.from(response);
  }

  // Creates a new project
  Future<Map<String, dynamic>> createProject(
      String orgId, Map<String, dynamic> projectData) async {
    final data = {
      ...projectData,
      'organization_id': orgId,
      'created_at': DateTime.now().toIso8601String()
    };
    final response =
        await _client.from('projects').insert(data).select().single();
    return response;
  }

  // Updates project repository/storage configuration
  Future<Map<String, dynamic>> updateProjectRepository(
      String projectId, Map<String, dynamic> repoConfig) async {
    final response = await _client
        .from('projects')
        .update(repoConfig)
        .eq('id', projectId)
        .select()
        .single();
    return response;
  }

  // Fetches project details including repository info
  Future<Map<String, dynamic>> fetchProject(String projectId) async {
    final response =
        await _client.from('projects').select().eq('id', projectId).single();
    return response;
  }
}
