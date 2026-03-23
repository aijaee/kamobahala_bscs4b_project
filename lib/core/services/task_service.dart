import 'package:supabase_flutter/supabase_flutter.dart';

class TaskService {
  final SupabaseClient _client = Supabase.instance.client;

  /// specific project
  Future<List<Map<String, dynamic>>> fetchProjectTasks(String projectId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId)
        .order('due_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// by category/section
  Future<Map<String, List<Map<String, dynamic>>>> fetchTasksByCategory(
      String projectId) async {
    final tasks = await fetchProjectTasks(projectId);
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final task in tasks) {
      final category = task['category'] ?? 'Uncategorized';
      grouped.putIfAbsent(category, () => []).add(task);
    }

    return grouped;
  }

  /// Create new task 
  Future<Map<String, dynamic>> createTask(
      String projectId, Map<String, dynamic> taskData) async {
    final data = {
      ...taskData,
      'project_id': projectId,
      'created_at': DateTime.now().toIso8601String()
    };
    final response =
        await _client.from('tasks').insert(data).select().single();

    return response;
  }

  /// Update
  Future<Map<String, dynamic>> updateTask(
      String taskId, Map<String, dynamic> updates) async {
    final response = await _client
        .from('tasks')
        .update(updates)
        .eq('id', taskId)
        .select()
        .single();

    return response;
  }

  /// Delete task and its associated financial transactions
  Future<bool> deleteTask(String taskId) async {
    try {
      print('Starting task deletion for taskId: $taskId');
      
      // First, verify the task exists
      final taskExists = await _client
          .from('tasks')
          .select('id')
          .eq('id', taskId)
          .maybeSingle();
      
      if (taskExists == null) {
        print('Task not found: $taskId');
        throw Exception('Task not found in database');
      }
      
      print('Task found, proceeding with deletion');
      
      // Delete associated financial transactions for this task first
      try {
        await _client
            .from('financial_transactions')
            .delete()
            .eq('task_id', taskId);
        print('Financial transactions deleted');
      } catch (e) {
        print('Note: Could not delete financial transactions: $e');
        // Don't fail if transactions don't exist
      }
      
      // Then delete the task itself - use eq() instead of match()
      print('Executing delete query for task: $taskId');
      await _client
          .from('tasks')
          .delete()
          .eq('id', taskId);
      
      print('Delete query executed successfully');
      
      // Give the database a moment to process the delete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify task was deleted
      final verifyDelete = await _client
          .from('tasks')
          .select('id')
          .eq('id', taskId)
          .maybeSingle();
      
      if (verifyDelete != null) {
        print('ERROR: Task still exists after delete attempt');
        throw Exception('Failed to delete task from database - row still exists after delete');
      }
      
      print('Task successfully deleted and verified');
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  /// Get completed task count for a project
  Future<int> getCompletedTaskCount(String projectId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId);

    // Filter with case-insensitive comparison to match project_overview logic
    final completedTasks = (response as List).where((task) {
      return (task['status'] ?? '').toString().toLowerCase() == 'completed';
    }).length;

    return completedTasks;
  }

  /// Get total task count for a project
  Future<int> getTotalTaskCount(String projectId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('project_id', projectId);

    return (response as List).length;
  }

  /// Calculate progress percentage (0.0 to 1.0)
  Future<double> calculateProjectProgress(String projectId) async {
    final total = await getTotalTaskCount(projectId);
    if (total == 0) return 0.0;

    final completed = await getCompletedTaskCount(projectId);
    return completed / total;
  }
}
