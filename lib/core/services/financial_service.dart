import 'package:supabase_flutter/supabase_flutter.dart';

class FinancialService {
  final SupabaseClient _client = Supabase.instance.client;

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

  double calculateBalance(
    Map<String, dynamic> organization,
    List<Map<String, dynamic>> transactions,
  ) {
    final openingBalance = _toDouble(organization['budget']);

    return openingBalance + transactions.fold<double>(
      0,
      (sum, transaction) => sum + signedAmount(transaction),
    );
  }

  double signedAmount(Map<String, dynamic> transaction) {
    final amount = _toDouble(transaction['amount']).abs();
    final type = (transaction['transaction_type'] ?? 'expense')
        .toString()
        .toLowerCase();

    return type == 'income' ? amount : -amount;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}