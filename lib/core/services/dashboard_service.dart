import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetches aggregated statistics for the main dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    final orgCount = await _client.from('organizations').count();
    final repoCount = await _client.from('repositories').count();

    return {
      'organization_count': orgCount,
      'repository_count': repoCount,
    };
  }
}
