import 'package:flutter/material.dart';
import '../core/services/task_service.dart';

class TasksViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Map<String, dynamic>> _tasks = [];
  Map<String, List<Map<String, dynamic>>> _tasksByCategory = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentProjectId;

  List<Map<String, dynamic>> get tasks => _tasks;
  Map<String, List<Map<String, dynamic>>> get tasksByCategory => _tasksByCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentProjectId => _currentProjectId;

  /// Fetches all tasks for a specific project
  Future<void> fetchProjectTasks(String projectId) async {
    _setLoading(true);
    _errorMessage = null;
    _currentProjectId = projectId;

    try {
      _tasks = await _taskService.fetchProjectTasks(projectId);
      _tasksByCategory = await _taskService.fetchTasksByCategory(projectId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to fetch tasks: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Creates a new task
  Future<bool> createTask(Map<String, dynamic> taskData) async {
    if (_currentProjectId == null) {
      _errorMessage = 'No project selected';
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final newTask =
          await _taskService.createTask(_currentProjectId!, taskData);
      _tasks.add(newTask);

      // Refresh grouped tasks
      _tasksByCategory = await _taskService.fetchTasksByCategory(_currentProjectId!);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create task: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Updates a task
  Future<bool> updateTask(String taskId, Map<String, dynamic> updates) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updated = await _taskService.updateTask(taskId, updates);

      // Update local task list
      final index = _tasks.indexWhere((task) => task['id'] == taskId);
      if (index != -1) {
        _tasks[index] = updated;
      }

      // Refresh grouped tasks
      if (_currentProjectId != null) {
        _tasksByCategory =
            await _taskService.fetchTasksByCategory(_currentProjectId!);
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update task: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Deletes a task
  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _taskService.deleteTask(taskId);

      // Remove from local task list
      _tasks.removeWhere((task) => task['id'] == taskId);

      // Refresh grouped tasks
      if (_currentProjectId != null) {
        _tasksByCategory =
            await _taskService.fetchTasksByCategory(_currentProjectId!);
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete task: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_currentProjectId != null) {
      await fetchProjectTasks(_currentProjectId!);
    }
  }
}
