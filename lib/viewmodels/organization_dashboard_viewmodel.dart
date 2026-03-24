import 'package:flutter/material.dart';
import '../core/services/dashboard_service.dart';
import 'financial_viewmodel.dart';

class OrganizationDashboardViewModel extends ChangeNotifier {
  final FinancialViewModel _financialViewModel;
  final DashboardService _dashboardService = DashboardService();

  double _currentBalance = 0;
  double _totalIncome = 0;
  double _totalExpenses = 0;
  String? _errorMessage;
  List<Map<String, dynamic>> _priorityDeadlines = [];
  List<Map<String, dynamic>> _assignedDeadlines =
      []; // For admin's assigned tasks
  bool _isLoadingDeadlines = false;

  double get currentBalance => _currentBalance;
  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get priorityDeadlines => _priorityDeadlines;
  List<Map<String, dynamic>> get assignedDeadlines => _assignedDeadlines;
  bool get isLoadingDeadlines => _isLoadingDeadlines;

  OrganizationDashboardViewModel({required FinancialViewModel financialViewModel})
      : _financialViewModel = financialViewModel;

  /// financial summary from organization data and transactions
  void calculateFinancialSummary(
    Map<String, dynamic> organization,
    List<Map<String, dynamic>> transactions,
  ) {
    try {
      _errorMessage = null;

      final openingBalance = _toDouble(organization['budget']);
      _totalIncome = 0;
      _totalExpenses = 0;

      // Calculate income and expenses (exclude budget allocations which are internal transfers)
      for (final transaction in transactions) {
        final title = (transaction['title'] ?? '').toString();
        final isInternalTransfer = title.contains('Budget Allocation') ||
            title.contains('Budget Adjustment');

        if (!isInternalTransfer) {
          final signedAmount = getSignedAmount(transaction);
          if (signedAmount > 0) {
            _totalIncome += signedAmount;
          } else {
            _totalExpenses += signedAmount.abs();
          }
        }
      }

      // Calculate current balance: opening balance + income - expenses
      _currentBalance = openingBalance + _totalIncome - _totalExpenses;
      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Failed to calculate financial summary: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Fetches priority deadlines for member view (all assigned tasks)
  Future<void> fetchMemberDeadlines(
    String organizationId,
    String? userEmail,
  ) async {
    _isLoadingDeadlines = true;
    notifyListeners();

    try {
      _priorityDeadlines = userEmail != null
          ? await _dashboardService.getMemberAssignedTasks(
              organizationId,
              userEmail,
            )
          : [];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to fetch deadlines: ${e.toString()}';
      _priorityDeadlines = [];
    }

    _isLoadingDeadlines = false;
    notifyListeners();
  }

  /// Fetches priority deadlines for admin view (all tasks)
  /// Also fetches assigned tasks separately
  Future<void> fetchAdminDeadlines(
    String organizationId,
    String? userEmail,
  ) async {
    _isLoadingDeadlines = true;
    notifyListeners();

    try {
      _priorityDeadlines =
          await _dashboardService.getAdminAllTasks(organizationId);
      
      _assignedDeadlines = userEmail != null
          ? await _dashboardService.getAdminAssignedTasks(
              organizationId,
              userEmail,
            )
          : [];
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to fetch deadlines: ${e.toString()}';
      _priorityDeadlines = [];
      _assignedDeadlines = [];
    }

    _isLoadingDeadlines = false;
    notifyListeners();
  }

  /// amount for a transaction (positive for income, negative for expense)
  double getSignedAmount(Map<String, dynamic> transaction) {
    final amount = _toDouble(transaction['amount']).abs();
    final type =
        (transaction['transaction_type'] ?? 'expense').toString().toLowerCase();

    return type == 'income' ? amount : -amount;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> refresh(Map<String, dynamic> organization) async {
    await _financialViewModel.refresh();
    calculateFinancialSummary(organization, _financialViewModel.transactions);
  }
}

