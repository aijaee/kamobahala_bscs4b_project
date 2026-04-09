import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/task.dart';
import 'financial_service.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Task>> fetchProjectTasks(String projectId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('due_date', ascending: true);

    return (response as List)
        .map((t) => Task.fromMap(t as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, List<Task>>> fetchTasksByCategory(String projectId) async {
    final tasks = await fetchProjectTasks(projectId);
    final Map<String, List<Task>> grouped = {};

    for (final task in tasks) {
      final category = task.category ?? 'Uncategorized';
      grouped.putIfAbsent(category, () => []).add(task);
    }

    return grouped;
  }

  Future<Task> createTask(
      String projectId, Map<String, dynamic> taskData) async {
    final data = {
      ...taskData,
      'project_id': projectId,
      'created_at': DateTime.now().toIso8601String()
    };
    final response =
        await _client.from('tasks').insert(data).select().single();

    final task = Task.fromMap(response);

    // Create financial transaction if deduct_from_budget is true and estimated_expense > 0
    final deductFromBudget = taskData['deduct_from_budget'] as bool? ?? false;
    final estimatedExpense = (taskData['estimated_expense'] as num?)?.toDouble() ?? 0.0;
    final organizationId = taskData['organization_id'] as String?;
    final taskTitle = taskData['title'] as String? ?? 'Task';

    if (deductFromBudget && estimatedExpense > 0 && organizationId != null) {
      try {
        final financialService = FinancialService();
        await financialService.createTransaction(
          organizationId,
          {
            'title': 'Task: $taskTitle',
            'description': 'Expense for task: $taskTitle',
            'department': 'Tasks',
            'transaction_type': 'expense',
            'amount': estimatedExpense,
            'occurred_at': DateTime.now().toIso8601String(),
            'task_id': task.id,
            'project_id': projectId,
          },
        );
      } catch (e) {
        print('Error creating financial transaction for task: $e');
        // Don't fail the task creation if transaction fails
        // Just log the error
      }
    }

    return task;
  }

  Future<Task> updateTask(
      String taskId, Map<String, dynamic> updates) async {
    final response = await _client
        .from('tasks')
        .update(updates)
        .eq('id', taskId)
        .select()
        .single();

    final task = Task.fromMap(response);

    // Handle financial transaction updates if needed
    // If estimated_expense or deduct_from_budget changed, we might need to update transactions
    // For now, just return the updated task
    // TODO: Implement transaction updates if financial details changed

    return task;
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      final taskExists = await _client
          .from('tasks')
          .select('id')
          .eq('id', taskId)
          .maybeSingle();
      if (taskExists == null) throw Exception('Task not found');
      // Delete associated financial transactions for this task first
      try {
        await _client
            .from('financial_transactions')
            .delete()
            .eq('task_id', taskId);
      } catch (e) {
        // Transactions may not exist
      }
      await _client
          .from('tasks')
          .delete()
          .eq('id', taskId);
      await Future.delayed(const Duration(milliseconds: 100));
      final verifyDelete = await _client
          .from('tasks')
          .select('id')
          .eq('id', taskId)
          .maybeSingle();
      if (verifyDelete != null) throw Exception('Delete failed');
      return true;
    } catch (e) {
      rethrow;
    }
  }
  Future<int> getCompletedTaskCount(String projectId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId);
    final completedTasks = (response as List).where((task) {
      return (task['status'] ?? '').toString().toLowerCase() == 'completed';
    }).length;

    return completedTasks;
  }

  /// Total task count
  Future<int> getTotalTaskCount(String projectId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId);

    return (response as List).length;
  }

  /// Progress percentage (0.0 to 1.0)
  Future<double> calculateProjectProgress(String projectId) async {
    final total = await getTotalTaskCount(projectId);
    if (total == 0) return 0.0;

    final completed = await getCompletedTaskCount(projectId);
    return completed / total;
  }

  /// Get user profile by user_id
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Get user profile by email
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('email', email)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Error fetching user profile by email: $e');
      return null;
    }
  }
}
