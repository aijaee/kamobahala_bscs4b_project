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

  /// Delete
  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }
}
