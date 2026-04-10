import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/financial_transaction.dart';

class FinancialService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<double?> fetchOrganizationBudget(String organizationId) async {
    final response = await _client
        .from('organizations')
        .select('budget')
        .eq('id', organizationId)
        .maybeSingle();

    final rawBudget = response?['budget'];
    if (rawBudget is num) {
      return rawBudget.toDouble();
    }
    if (rawBudget is String) {
      return double.tryParse(rawBudget);
    }
    return null;
  }

  Future<Set<String>> fetchCompletedProjectIds(String organizationId) async {
    final response = await _client
        .from('projects')
        .select('id,status')
        .eq('organization_id', organizationId);

    return (response as List)
        .where((row) {
          final status =
              ((row as Map<String, dynamic>)['status']?.toString() ?? '')
                  .toLowerCase()
                  .trim();
          return status == 'completed' || status == 'complete';
        })
        .map((row) => (row as Map<String, dynamic>)['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  /// Fetches all transactions for a specific organization
  Future<List<FinancialTransaction>> fetchTransactions(String organizationId) async {
    final response = await _client
        .from('financial_transactions')
        .select()
        .eq('organization_id', organizationId)
        .order('occurred_at', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((t) => FinancialTransaction.fromMap(t as Map<String, dynamic>))
        .toList();
  }

  Future<FinancialTransaction> createTransaction(
    String organizationId,
    Map<String, dynamic> transactionData,
  ) async {
    final data = {
      ...transactionData,
      'organization_id': organizationId,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('financial_transactions')
        .insert(data)
        .select()
        .single();

    return FinancialTransaction.fromMap(response);
  }

  /// Delete a transaction by its ID
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _client
          .from('financial_transactions')
          .delete()
          .eq('id', transactionId);
      return true;
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  /// Update a transaction by its ID
  Future<FinancialTransaction?> updateTransaction(
    String transactionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _client
          .from('financial_transactions')
          .update(updates)
          .eq('id', transactionId)
          .select()
          .single();

      return FinancialTransaction.fromMap(response);
    } catch (e) {
      print('Error updating transaction: $e');
      return null;
    }
  }

  /// Delete all transactions associated with a task
  Future<bool> deleteTaskTransactions(String taskId) async {
    try {
      await _client
          .from('financial_transactions')
          .delete()
          .eq('task_id', taskId);
      return true;
    } catch (e) {
      print('Error deleting task transactions: $e');
      return false;
    }
  }
}