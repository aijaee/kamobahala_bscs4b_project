import 'package:supabase_flutter/supabase_flutter.dart';
class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchProjects(String orgId) async {
    final response =
        await _client.from('projects').select().eq('organization_id', orgId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createProject(
      String orgId, Map<String, dynamic> projectData) async {
    final data = {
      ...projectData,
      'organization_id': orgId,
      'created_at': DateTime.now().toIso8601String()
    };
    final response =
        await _client.from('projects').insert(data).select().single();

    // Create budget allocation transaction if budget is provided
    final budget = projectData['budget'];
    if (budget != null && budget > 0) {
      await _createBudgetAllocationTransaction(
        orgId,
        response['id'],
        projectData['name'] ?? 'Unnamed Project',
        budget,
        DateTime.now().toIso8601String(),
      );
    }

    return response;
  }

  /// Creates a budget allocation transaction in financial_transactions
  Future<void> _createBudgetAllocationTransaction(
    String organizationId,
    String projectId,
    String projectName,
    double budget,
    String occurredAt, {
    bool isBudgetAdjustment = false,
  }) async {
    final transactionData = {
      'organization_id': organizationId,
      'title': isBudgetAdjustment
          ? 'Budget Adjustment: $projectName'
          : 'Budget Allocation: $projectName',
      'description': isBudgetAdjustment
          ? 'Budget adjustment for project'
          : 'Budget allocated for project',
      'department': 'Projects',
      'transaction_type': 'expense',
      'amount': budget,
      'occurred_at': occurredAt,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await _client.from('financial_transactions').insert(transactionData);
    } catch (e) {
      print('Error creating budget allocation transaction: $e');
      // Continue with project update even if transaction fails
    }
  }

  /// Updates project repository/storage configuration
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

  /// Fetches project details including repository info
  Future<Map<String, dynamic>> fetchProject(String projectId) async {
    final response =
        await _client.from('projects').select().eq('id', projectId).single();
    return response;
  }

  /// Updates a project with new data and handles budget changes
  Future<Map<String, dynamic>> updateProject(
      String projectId, Map<String, dynamic> updates) async {
    // Fetch old project to check for budget changes
    final oldProject = await fetchProject(projectId);
    final oldBudget = (oldProject['budget'] as num?)?.toDouble() ?? 0;
    final newBudget = (updates['budget'] as num?)?.toDouble() ?? oldBudget;

    final response = await _client
        .from('projects')
        .update(updates)
        .eq('id', projectId)
        .select()
        .single();

    // Handle budget changes
    if (newBudget != oldBudget && newBudget > 0) {
      await _createBudgetAllocationTransaction(
        oldProject['organization_id'],
        projectId,
        updates['name'] ?? oldProject['name'] ?? 'Unnamed Project',
        newBudget,
        DateTime.now().toIso8601String(),
        isBudgetAdjustment: newBudget > oldBudget,
      );
    }

    return response;
  }

  /// Deletes a project
  Future<void> deleteProject(String projectId) async {
    await _client.from('projects').delete().eq('id', projectId);
  }

  /// Fetches active projects for an organization (status != 'completed')
  Future<List<Map<String, dynamic>>> fetchActiveProjects(String orgId) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('organization_id', orgId)
        .neq('status', 'completed');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetches completed projects for an organization
  Future<List<Map<String, dynamic>>> fetchCompletedProjects(String orgId) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('organization_id', orgId)
        .eq('status', 'completed');

    return List<Map<String, dynamic>>.from(response);
  }
}
