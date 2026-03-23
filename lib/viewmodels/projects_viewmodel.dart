import 'package:flutter/material.dart';
import '../core/services/project_service.dart';
import '../core/services/task_service.dart';

class ProjectsViewModel extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _completedProjects = [];
  Map<String, dynamic>? _currentProject;
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentOrganizationId;

  List<Map<String, dynamic>> get projects => _projects;
  List<Map<String, dynamic>> get completedProjects => _completedProjects;
  Map<String, dynamic>? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentOrganizationId => _currentOrganizationId;

  /// Fetches all projects for a specific organization
  Future<void> fetchProjects(String orgId) async {
    _setLoading(true);
    _errorMessage = null;
    _currentOrganizationId = orgId;

    try {
      _projects = await _projectService.fetchProjects(orgId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to fetch projects: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Fetches a specific project by ID
  Future<void> fetchProject(String projectId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _currentProject = await _projectService.fetchProject(projectId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to fetch project details: ${e.toString()}';
      _setLoading(false);
    }
  }

  /// Creates a new project in the current organization
  Future<bool> createProject(Map<String, dynamic> projectData) async {
    if (_currentOrganizationId == null) {
      _errorMessage = 'No organization selected';
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
      return false;
    }
  }

  /// Updates project repository/storage configuration
  Future<bool> updateProjectRepository(
      String projectId, Map<String, dynamic> repoConfig) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _projectService.updateProjectRepository(projectId, repoConfig);

      // Update local project list
      final index =
          _projects.indexWhere((project) => project['id'] == projectId);
      if (index != -1) {
        _projects[index] = {..._projects[index], ...repoConfig};
      }

      // Update current project if it matches
      if (_currentProject != null && _currentProject!['id'] == projectId) {
        _currentProject = {..._currentProject!, ...repoConfig};
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage =
          'Failed to update project repository: ${e.toString()}';
      _setLoading(false);
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
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      _completedProjects = await _projectService
          .fetchCompletedProjects(_currentOrganizationId!);
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to fetch completed projects: ${e.toString()}';
      _setLoading(false);
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
      final index = _projects.indexWhere((p) => p['id'] == projectId);
      if (index != -1) {
        _projects[index] = updated;
      }

      // Update current project if it matches
      if (_currentProject != null && _currentProject!['id'] == projectId) {
        _currentProject = updated;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update project: ${e.toString()}';
      _setLoading(false);
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
      _projects.removeWhere((p) => p['id'] == projectId);

      // Clear current project if it matches
      if (_currentProject != null && _currentProject!['id'] == projectId) {
        _currentProject = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete project: ${e.toString()}';
      _setLoading(false);
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
  Future<List<Map<String, dynamic>>> fetchProjectsWithProgress(String orgId) async {
    _setLoading(true);
    _errorMessage = null;
    _currentOrganizationId = orgId;

    try {
      _projects = await _projectService.fetchProjects(orgId);
      
      // Add progress to each project
      for (var project in _projects) {
        final progress = await getProjectProgress(project['id']);
        project['progress'] = progress;
      }
      
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to fetch projects: ${e.toString()}';
      _setLoading(false);
    }
    return _projects;
  }
}
