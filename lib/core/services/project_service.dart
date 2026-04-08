import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/project.dart';

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Project>> fetchProjects(String orgId) async {
    final response =
        await _client.from('projects').select().eq('organization_id', orgId);

    return (response as List)
        .map((p) => Project.fromMap(p as Map<String, dynamic>))
        .toList();
  }

  Future<Project> createProject(
      String orgId, Map<String, dynamic> projectData) async {
    final data = {
      ...projectData,
      'organization_id': orgId,
      'created_at': DateTime.now().toIso8601String()
    };
    final response =
        await _client.from('projects').insert(data).select().single();

    final project = Project.fromMap(response);

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

    return project;
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
  Future<Project> updateProjectRepository(
      String projectId, Map<String, dynamic> repoConfig) async {
    final response = await _client
        .from('projects')
        .update(repoConfig)
        .eq('id', projectId)
        .select()
        .single();
    return Project.fromMap(response);
  }

  /// Fetches project details including repository info
  Future<Project> fetchProject(String projectId) async {
    final response =
        await _client.from('projects').select().eq('id', projectId).single();
    return Project.fromMap(response);
  }

  /// Updates a project with new data and handles budget changes
  Future<Project> updateProject(
      String projectId, Map<String, dynamic> updates) async {
    // Fetch old project to check for budget changes
    final oldProject = await fetchProject(projectId);
    final oldBudget = oldProject.budget ?? 0;
    final newBudget = (updates['budget'] as num?)?.toDouble() ?? oldBudget;

    final response = await _client
        .from('projects')
        .update(updates)
        .eq('id', projectId)
        .select()
        .single();

    final updatedProject = Project.fromMap(response);

    // Handle budget changes
    if (newBudget != oldBudget && newBudget > 0) {
      await _createBudgetAllocationTransaction(
        oldProject.organizationId,
        projectId,
        updates['name'] ?? oldProject.name,
        newBudget,
        DateTime.now().toIso8601String(),
        isBudgetAdjustment: newBudget > oldBudget,
      );
    }

    return updatedProject;
  }

  /// Deletes a project
  Future<void> deleteProject(String projectId) async {
    await _client.from('projects').delete().eq('id', projectId);
  }

  /// Fetches active projects for an organization (status != 'completed')
  Future<List<Project>> fetchActiveProjects(String orgId) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('organization_id', orgId)
        .neq('status', 'completed');

    return (response as List)
        .map((p) => Project.fromMap(p as Map<String, dynamic>))
        .toList();
  }

  /// Fetches completed projects for an organization
  Future<List<Project>> fetchCompletedProjects(String orgId) async {
    final response = await _client
        .from('projects')
        .select()
        .eq('organization_id', orgId)
        .eq('status', 'completed');

    return (response as List)
        .map((p) => Project.fromMap(p as Map<String, dynamic>))
        .toList();
  }
}
