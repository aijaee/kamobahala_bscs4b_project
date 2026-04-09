import 'package:supabase_flutter/supabase_flutter.dart';
class FinancialService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetches all transactions for a specific organization
  Future<List<Map<String, dynamic>>> fetchTransactions(String organizationId) async {
    final response = await _client
        .from('financial_transactions')
        .select()
        .eq('organization_id', organizationId)
        .order('occurred_at', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createTransaction(
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

    return response;
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