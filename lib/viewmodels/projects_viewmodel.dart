import 'package:flutter/material.dart';
import '../core/services/project_service.dart';
import '../core/services/task_service.dart';
import '../models/project.dart';

class ProjectsViewModel extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();

  List<Project> _projects = [];
  List<Project> _completedProjects = [];
  Project? _currentProject;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentOrganizationId;
  Map<String, double> _projectProgressCache = {};

  List<Project> get projects => _projects;
  List<Project> get completedProjects => _completedProjects;
  Project? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentOrganizationId => _currentOrganizationId;
  Map<String, double> get projectProgressCache => _projectProgressCache;

  /// Fetches all projects for a specific organization
  Future<void> fetchProjects(String orgId) async {
    _setLoading(true);
    _errorMessage = null;
    _currentOrganizationId = orgId;

    try {
      _projects = await _projectService.fetchProjects(orgId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch projects: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Fetches a specific project by ID
  Future<void> fetchProject(String projectId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentProject = await _projectService.fetchProject(projectId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch project details: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Creates a new project in the current organization
  Future<bool> createProject(Map<String, dynamic> projectData) async {
    if (_currentOrganizationId == null) {
      _errorMessage = 'No organization selected';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final newProject = await _projectService.createProject(
        _currentOrganizationId!,
        projectData,
      );

      _projects.add(newProject);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create project: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Updates project repository/storage configuration
  Future<bool> updateProjectRepository(
      String projectId, Map<String, dynamic> repoConfig) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updated =
          await _projectService.updateProjectRepository(projectId, repoConfig);

      // Update local project list
      final index = _projects.indexWhere((project) => project.id == projectId);
      if (index != -1) {
        _projects[index] = updated;
      }

      // Update current project if it matches
      if (_currentProject != null && _currentProject!.id == projectId) {
        _currentProject = updated;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update project repository: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Helper method to manage loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refreshes projects for the current organization
  Future<void> refresh() async {
    if (_currentOrganizationId != null) {
      await fetchProjects(_currentOrganizationId!);
    }
  }

  /// Fetches completed projects for the current organization
  Future<void> fetchCompletedProjects() async {
    if (_currentOrganizationId == null) {
      _errorMessage = 'No organization selected';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _completedProjects =
          await _projectService.fetchCompletedProjects(_currentOrganizationId!);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch completed projects: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Updates an existing project
  Future<bool> updateProject(
      String projectId, Map<String, dynamic> updates) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final updated = await _projectService.updateProject(projectId, updates);

      // Update local project list
      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        _projects[index] = updated;
      }

      // Update current project if it matches
      if (_currentProject != null && _currentProject!.id == projectId) {
        _currentProject = updated;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update project: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Deletes a project
  Future<bool> deleteProject(String projectId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _projectService.deleteProject(projectId);

      // Remove from local project list
      _projects.removeWhere((p) => p.id == projectId);

      // Clear current project if it matches
      if (_currentProject != null && _currentProject!.id == projectId) {
        _currentProject = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete project: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Calculates progress percentage for a project based on tasks
  Future<double> getProjectProgress(String projectId) async {
    try {
      return await _taskService.calculateProjectProgress(projectId);
    } catch (e) {
      print('Error calculating project progress: $e');
      return 0.0;
    }
  }

  /// Fetches all projects with progress data
  Future<List<Project>> fetchProjectsWithProgress(String orgId) async {
    _setLoading(true);
    _errorMessage = null;
    _currentOrganizationId = orgId;

    try {
      _projects = await _projectService.fetchProjects(orgId);
      _setLoading(false);
      notifyListeners();

      // Load progress for all projects in batch
      await _loadAllProjectProgress();

      return _projects;
    } catch (e) {
      _errorMessage = 'Failed to fetch projects: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  /// Batch loads progress for all current projects and caches the results
  Future<void> _loadAllProjectProgress() async {
    try {
      _projectProgressCache.clear();

      for (final project in _projects) {
        try {
          final progress =
              await _taskService.calculateProjectProgress(project.id);
          _projectProgressCache[project.id] = progress;
        } catch (e) {
          print('Error calculating progress for project ${project.id}: $e');
          _projectProgressCache[project.id] = 0.0;
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading project progress batch: $e');
    }
  }

  /// Gets cached progress for a project, returns 0.0 if not cached
  double getProjectProgressFromCache(String projectId) {
    return _projectProgressCache[projectId] ?? 0.0;
  }

  /// Clears all project data (used when switching organizations)
  void clearProjects() {
    _projects.clear();
    _completedProjects.clear();
    _currentProject = null;
    _currentOrganizationId = null;
    _errorMessage = null;
    _projectProgressCache.clear();
    notifyListeners();
  }
}
