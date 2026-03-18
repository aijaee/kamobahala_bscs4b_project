import 'package:flutter/material.dart';
import 'financial_viewmodel.dart';

class OrganizationDashboardViewModel extends ChangeNotifier {
  final FinancialViewModel _financialViewModel;

  double _currentBalance = 0;
  double _totalIncome = 0;
  double _totalExpenses = 0;
  String? _errorMessage;

  double get currentBalance => _currentBalance;
  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;
  String? get errorMessage => _errorMessage;

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

      // Calculate income and expenses
      for (final transaction in transactions) {
        final signedAmount = getSignedAmount(transaction);
        if (signedAmount > 0) {
          _totalIncome += signedAmount;
        } else {
          _totalExpenses += signedAmount.abs();
        }
      }

      // Calculate current balance
      _currentBalance = openingBalance + _totalIncome - _totalExpenses;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to calculate financial summary: ${e.toString()}';
      notifyListeners();
    }
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
