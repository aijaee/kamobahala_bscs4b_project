import 'package:flutter/material.dart';
import '../core/services/depository_service.dart';

class DepositoryViewModel extends ChangeNotifier {
  final DepositoryService _depositoryService = DepositoryService();

  List<Map<String, dynamic>> _repositories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get repositories => _repositories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRepositories() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _repositories = await _depositoryService.getRepositories();
      _setLoading(false);
    } catch (e) {
      _errorMessage = 'Failed to fetch repositories: ${e.toString()}';
      _setLoading(false);
    }
  }

  Future<bool> createRepository(Map<String, dynamic> data) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final newRepository =
          await _depositoryService.createRepository(data);
      _repositories.add(newRepository);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create repository: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateRepository(
      String id, Map<String, dynamic> data) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _depositoryService.updateRepository(id, data);
      final index = _repositories.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        _repositories[index] = {..._repositories[index], ...data};
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update repository: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteRepository(String id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _depositoryService.deleteRepository(id);
      _repositories.removeWhere((r) => r['id'] == id);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete repository: ${e.toString()}';
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
}
