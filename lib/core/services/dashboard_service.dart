import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _client = Supabase.instance.client;

  // TODO: [MVVM] move this call to MainDashboardViewModel and expose as provider state
  // Fetches aggregated statistics for the main dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    final orgCount = await _client.from('organizations').count();
    final repoCount = await _client.from('repositories').count();

    return {
      'organization_count': orgCount,
      'repository_count': repoCount,
    };
  }

  /// Fetches all tasks for admin view (all tasks in organization)
  Future<List<Map<String, dynamic>>> getAdminAllTasks(
    String organizationId,
  ) async {
    try {
      // Get all projects in organization
      final projects = await _client
          .from('projects')
          .select()
          .eq('organization_id', organizationId);

      final allTasks = <Map<String, dynamic>>[];

      // For each project, fetch all tasks
      for (var project in projects) {
        final projectId = project['id'];
        final tasks = await _client
            .from('tasks')
            .select()
            .eq('project_id', projectId)
            .neq('status', 'completed')
            .order('priority', ascending: true);

        for (var task in tasks) {
          allTasks.add({
            ...task,
            'projectName': project['name'] ?? 'Untitled Project',
            'projectId': projectId,
          });
        }
      }

      // Sort by priority: High -> Medium -> Low, then by due date
      allTasks.sort((a, b) {
        final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
        final aPriority = priorityOrder[a['priority'] ?? 'Low'] ?? 2;
        final bPriority = priorityOrder[b['priority'] ?? 'Low'] ?? 2;

        if (aPriority != bPriority) return aPriority.compareTo(bPriority);

        // If same priority, sort by due date
        final aDueDate =
            a['due_date'] != null ? DateTime.parse(a['due_date']) : null;
        final bDueDate =
            b['due_date'] != null ? DateTime.parse(b['due_date']) : null;

        if (aDueDate == null) return 1;
        if (bDueDate == null) return -1;
        return aDueDate.compareTo(bDueDate);
      });

      return allTasks;
    } catch (e) {
      print('Error fetching admin all tasks: $e');
      return [];
    }
  }

  /// Fetches tasks assigned to the admin (by email)
  Future<List<Map<String, dynamic>>> getAdminAssignedTasks(
    String organizationId,
    String userEmail,
  ) async {
    return _getAssignedTasksForUser(
      organizationId: organizationId,
      userEmail: userEmail,
      errorContext: 'admin assigned',
    );
  }

  /// Fetches tasks assigned to member (by email)
  Future<List<Map<String, dynamic>>> getMemberAssignedTasks(
    String organizationId,
    String userEmail,
  ) async {
    return _getAssignedTasksForUser(
      organizationId: organizationId,
      userEmail: userEmail,
      errorContext: 'member assigned',
    );
  }

  Future<List<Map<String, dynamic>>> _getAssignedTasksForUser({
    required String organizationId,
    required String userEmail,
    required String errorContext,
  }) async {
    try {
      // Get all projects in organization
      final projects = await _client
          .from('projects')
          .select()
          .eq('organization_id', organizationId);

      final assignedTasks = <Map<String, dynamic>>[];

      // For each project, fetch tasks assigned to this user
      for (var project in projects) {
        final projectId = project['id'];
        final tasks = await _client
            .from('tasks')
            .select()
            .eq('project_id', projectId)
            .eq('assignee', userEmail)
            .neq('status', 'completed')
            .order('priority', ascending: true);

        for (var task in tasks) {
          assignedTasks.add({
            ...task,
            'projectName': project['name'] ?? 'Untitled Project',
            'projectId': projectId,
          });
        }
      }

      // Sort by priority
      assignedTasks.sort((a, b) {
        final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
        final aPriority = priorityOrder[a['priority'] ?? 'Low'] ?? 2;
        final bPriority = priorityOrder[b['priority'] ?? 'Low'] ?? 2;

        if (aPriority != bPriority) return aPriority.compareTo(bPriority);

        final aDueDate =
            a['due_date'] != null ? DateTime.parse(a['due_date']) : null;
        final bDueDate =
            b['due_date'] != null ? DateTime.parse(b['due_date']) : null;

        if (aDueDate == null) return 1;
        if (bDueDate == null) return -1;
        return aDueDate.compareTo(bDueDate);
      });

      return assignedTasks;
    } catch (e) {
      print('Error fetching $errorContext tasks: $e');
      return [];
    }
  }

  /// Get priority level as a display string and color
  static Map<String, dynamic> getPriorityInfo(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return {
          'label': 'High Priority',
          'color': 0xFFEF4444, // Red
          'icon': 0xE896, // Error icon
        };
      case 'medium':
        return {
          'label': 'Medium Priority',
          'color': 0xFFF97316, // Orange
          'icon': 0xE002, // Warning icon
        };
      case 'low':
        return {
          'label': 'Low Priority',
          'color': 0xFF22C55E, // Green
          'icon': 0xE192, // Info icon
        };
      default:
        return {
          'label': 'Low Priority',
          'color': 0xFF22C55E,
          'icon': 0xE192,
        };
    }
  }
}
