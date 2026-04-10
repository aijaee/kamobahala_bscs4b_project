import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/project.dart';
import 'financial_service.dart';

class ProjectService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Project>> fetchProjects(String orgId) async {
    final response =
        await _client.from('projects').select().eq('organization_id', orgId).neq('status', 'completed');

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
    String transactionType = 'expense',
  }) async {
    final normalizedAmount = budget.abs();
    if (normalizedAmount <= 0) {
      return;
    }

    final transactionData = {
      'organization_id': organizationId,
      'title': isBudgetAdjustment
          ? 'Budget Adjustment: $projectName'
          : 'Budget Allocation: $projectName',
      'description': isBudgetAdjustment
          ? 'Budget adjustment for project'
          : 'Budget allocated for project',
      'department': 'Projects',
      'transaction_type': transactionType,
      'amount': normalizedAmount,
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
    final oldStatus = oldProject.status?.toLowerCase();
    final oldBudget = oldProject.budget ?? 0;
    final rawBudget = updates['budget'];
    final newBudget = rawBudget is num
      ? rawBudget.toDouble()
      : double.tryParse(rawBudget?.toString() ?? '') ?? oldBudget;

    final response = await _client
        .from('projects')
        .update(updates)
        .eq('id', projectId)
        .select()
        .single();

    final updatedProject = Project.fromMap(response);
    final newStatus = updatedProject.status?.toLowerCase();

    // Increase in project budget reduces depository (expense), decrease refunds it (income).
    final budgetDelta = newBudget - oldBudget;
    if (budgetDelta != 0) {
      await _createBudgetAllocationTransaction(
        oldProject.organizationId,
        projectId,
        updates['name'] ?? oldProject.name,
        budgetDelta,
        DateTime.now().toIso8601String(),
        isBudgetAdjustment: true,
        transactionType: budgetDelta > 0 ? 'expense' : 'income',
      );
    }

    if (oldStatus != 'completed' && newStatus == 'completed') {
      await _syncTaskTransactionsForCompletedProject(updatedProject);
    } else if (oldStatus == 'completed' && newStatus != 'completed') {
      await _deleteProjectTaskTransactions(projectId);
    }

    return updatedProject;
  }

  Future<void> _syncTaskTransactionsForCompletedProject(Project project) async {
    try {
      await _deleteProjectTaskTransactions(project.id);

      final tasksResponse = await _client
          .from('tasks')
          .select('id,title,estimated_expense,deduct_from_budget')
          .eq('project_id', project.id);

      final tasks = (tasksResponse as List)
          .map((row) => row as Map<String, dynamic>)
          .toList();

      final now = DateTime.now().toIso8601String();
      final financialService = FinancialService();

      for (final task in tasks) {
        final amount = (task['estimated_expense'] as num?)?.toDouble() ?? 0.0;
        if (amount <= 0) {
          continue;
        }

        final taskId = task['id']?.toString() ?? '';
        if (taskId.isEmpty) {
          continue;
        }

        final taskTitle = (task['title'] as String?)?.trim();
        final title = (taskTitle == null || taskTitle.isEmpty) ? 'Task' : taskTitle;
        final deductFromBudget = task['deduct_from_budget'] as bool? ?? false;

        final transactionType = deductFromBudget ? 'expense' : 'income';
        final descriptionPrefix = deductFromBudget ? 'Expense' : 'Income';

        await financialService.createTransaction(
          project.organizationId,
          {
            'title': 'Task: $title',
            'description':
                '$descriptionPrefix for task: $title (Project: ${project.name})',
            'department': 'Tasks',
            'transaction_type': transactionType,
            'amount': amount,
            'occurred_at': now,
            'task_id': taskId,
            'project_id': project.id,
          },
        );
      }
    } catch (e) {
      print('Error syncing completed project task transactions: $e');
    }
  }

  Future<void> _deleteProjectTaskTransactions(String projectId) async {
    try {
      await _client
          .from('financial_transactions')
          .delete()
          .eq('project_id', projectId)
          .not('task_id', 'is', null);
    } catch (e) {
      print('Error deleting project task transactions: $e');
    }
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
