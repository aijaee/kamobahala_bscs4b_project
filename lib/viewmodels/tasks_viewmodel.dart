import 'package:flutter/material.dart';
import '../core/services/task_service.dart';
import '../models/task.dart';

class TasksViewModel extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Task> _tasks = [];
  Map<String, List<Task>> _tasksByCategory = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentProjectId;

  List<Task> get tasks => _tasks;
  Map<String, List<Task>> get tasksByCategory => _tasksByCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentProjectId => _currentProjectId;

  /// Fetches all tasks for a specific project
  Future<void> fetchProjectTasks(String projectId) async {
    // If switching to a different project, clear old tasks immediately
    if (_currentProjectId != projectId) {
      _tasks = [];
      _tasksByCategory = {};
      _currentProjectId = projectId;
      notifyListeners(); // Notify immediately when clearing tasks
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _tasks = await _taskService.fetchProjectTasks(projectId);
      _tasksByCategory = await _taskService.fetchTasksByCategory(projectId);
      _setLoading(false);
      notifyListeners(); // Ensure UI is updated after tasks are loaded
    } catch (e) {
      _errorMessage = 'Failed to fetch tasks: ${e.toString()}';
      _setLoading(false);
      notifyListeners(); // Notify about error
    }
  }

  /// Creates a new task
  Future<bool> createTask(Map<String, dynamic> taskData) async {
    if (_currentProjectId == null) {
      _errorMessage = 'No project selected';
      notifyListeners();
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
      notifyListeners();
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
      final index = _tasks.indexWhere((task) => task.id == taskId);
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
      notifyListeners();
      return false;
    }
  }

  /// Deletes a task
  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _taskService.deleteTask(taskId);
      
      if (!success) {
        throw Exception('Failed to delete task from database');
      }

      // Remove from local task list
      _tasks.removeWhere((task) => task.id == taskId);

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
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clears all tasks and resets the current project ID
  void clearTasks() {
    _tasks = [];
    _tasksByCategory = {};
    _currentProjectId = null;
    _errorMessage = null;
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
