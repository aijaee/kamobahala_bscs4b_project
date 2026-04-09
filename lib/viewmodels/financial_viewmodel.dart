import 'package:flutter/material.dart';
import '../core/services/financial_service.dart';
import '../models/financial_transaction.dart';

class FinancialViewModel extends ChangeNotifier {
  final FinancialService _financialService = FinancialService();

  List<FinancialTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentOrganizationId;

  final List<String> _filters = ['All', 'Income', 'Expenses'];
  int _selectedFilterIndex = 0;

  List<FinancialTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentOrganizationId => _currentOrganizationId;
  List<String> get filters => _filters;
  int get selectedFilterIndex => _selectedFilterIndex;

  /// Get transactions based on current filter
  List<FinancialTransaction> get filteredTransactions {
    if (_selectedFilterIndex == 1) {
      return _transactions.where((transaction) => transaction.isIncome).toList();
    }

    if (_selectedFilterIndex == 2) {
      return _transactions.where((transaction) => transaction.isExpense).toList();
    }

    return _transactions;
  }

  /// grouped transactions by date
  List<(String, List<FinancialTransaction>)> get groupedTransactions {
    final filtered = filteredTransactions;
    final Map<String, List<FinancialTransaction>> groups = {};

    for (final transaction in filtered) {
      final key = _dateHeaderLabel(transaction.occurredAt);
      groups.putIfAbsent(key, () => []).add(transaction);
    }

    return groups.entries.map((entry) => (entry.key, entry.value)).toList();
  }

  ///all transactions for a specific organization
  Future<void> fetchTransactions(String organizationId) async {
    _setLoading(true);
    _errorMessage = null;
    _currentOrganizationId = organizationId;

    try {
      _transactions = await _financialService.fetchTransactions(organizationId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to fetch transactions: ${e.toString()}';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Sets current organization for financial operations
  void setCurrentOrganization(String organizationId) {
    _currentOrganizationId = organizationId;
  }

  /// Creates new transaction for current organization
  Future<bool> createTransaction(Map<String, dynamic> transactionData) async {
    if (_currentOrganizationId == null) {
      _errorMessage = 'No organization selected';
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final newTransaction = await _financialService.createTransaction(
        _currentOrganizationId!,
        transactionData,
      );

      // Add to local list at the beginning (most recent first)
      _transactions.insert(0, newTransaction);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create transaction: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Deletes all financial transactions associated with a task
  Future<bool> deleteTaskTransactions(String taskId) async {
    _errorMessage = null;

    try {
      final success = await _financialService.deleteTaskTransactions(taskId);

      if (success) {
        // Remove transactions from local list
        _transactions.removeWhere((transaction) => transaction.taskId == taskId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete task transactions: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing transaction
  Future<bool> updateTransaction(
    String transactionId,
    Map<String, dynamic> updates,
  ) async {
    _errorMessage = null;

    try {
      final updated = await _financialService.updateTransaction(transactionId, updates);

      if (updated != null) {
        // Update in local list
        final index = _transactions.indexWhere((t) => t.id == transactionId);
        if (index != -1) {
          _transactions[index] = updated;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update transaction: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void updateFilter(int filterIndex) {
    if (filterIndex >= 0 && filterIndex < _filters.length) {
      _selectedFilterIndex = filterIndex;
      notifyListeners();
    }
  }

  double get currentBalance {
    return _transactions.fold<double>(
      0.0,
      (sum, transaction) => sum + getSignedAmount(transaction),
    );
  }

  /// Calculate available balance excluding internal transfers (budget allocations/adjustments).
  /// Formula: openingBudget + (Income - Expenses)
  /// This is the true available balance for budget allocation decisions.
  double calculateAvailableBalance(double openingBudget) {
    double totalIncome = 0;
    double totalExpenses = 0;

    for (final transaction in _transactions) {
      final title = transaction.title.toLowerCase();
      final isInternalTransfer = title.contains('budget allocation') ||
          title.contains('budget adjustment');
      final isCompletionBookkeeping = title.contains('project completed');

      if (!isInternalTransfer && !isCompletionBookkeeping) {
        if (transaction.isIncome) {
          totalIncome += transaction.amount;
        } else {
          totalExpenses += transaction.amount;
        }
      }
    }

    return openingBudget + totalIncome - totalExpenses;
  }

  double getSignedAmount(FinancialTransaction transaction) {
    final title = transaction.title.toLowerCase();

    // Treat budget allocations as positive (they're internal transfers, not expenses)
    if (title.contains('budget allocation') || title.contains('budget adjustment')) {
      return transaction.amount;
    }

    // Completion entries are bookkeeping records and should not impact balance.
    if (title.contains('project completed')) {
      return 0.0;
    }

    return transaction.isIncome ? transaction.amount : -transaction.amount;
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
    if (_currentOrganizationId != null) {
      await fetchTransactions(_currentOrganizationId!);
    }
  }

  String _dateHeaderLabel(DateTime date) {
    final today = DateTime.now();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final difference = normalizedToday.difference(normalizedDate).inDays;

    if (difference == 0) {
      return 'TODAY';
    }
    if (difference == 1) {
      return 'YESTERDAY';
    }

    return '${_monthName(date.month)} ${date.day}, ${date.year}'.toUpperCase();
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// Clears all transaction data (used when switching organizations)
  void clearTransactions() {
    _transactions.clear();
    _currentOrganizationId = null;
    _errorMessage = null;
    _selectedFilterIndex = 0;
    notifyListeners();
  }
}
