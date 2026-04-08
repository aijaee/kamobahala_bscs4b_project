import 'package:flutter/material.dart';
import '../core/services/dashboard_service.dart';
import '../models/financial_transaction.dart';
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


  void calculateFinancialSummary(
    Map<String, dynamic> organization,
    List<FinancialTransaction> transactions,
  ) {
    try {
      _errorMessage = null;

      final openingBalance = _toDouble(organization['budget']);
      _totalIncome = 0;
      _totalExpenses = 0;

      // Calculate income and expenses (exclude budget allocations which are internal transfers)
      for (final transaction in transactions) {
        final title = transaction.title.toLowerCase();
        final isInternalTransfer = title.contains('budget allocation') ||
            title.contains('budget adjustment');

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
  double getSignedAmount(FinancialTransaction transaction) {
    final amount = transaction.amount;
    final title = transaction.title.toLowerCase();

    // Treat budget allocations as positive (they're internal transfers, not expenses)
    if (title.contains('budget allocation') || title.contains('budget adjustment')) {
      return amount;
    }

    return transaction.isIncome ? amount : -amount;
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

