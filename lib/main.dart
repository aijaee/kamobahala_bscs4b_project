import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth/login_screen.dart';
// 1. Ensure these imports are correct
import 'views/dashboard/organization_dashboard.dart';
import 'views/projects/project_overview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL',
        defaultValue: 'https://amsjmwqryadpdqqaccdd.supabase.co'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_uleIRBilKfGYYjsYZyJOCA_omfSpd6e'),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Kamo Bahala",

        // 2. TEMPORARY BYPASS: Pass a dummy organization map
        home: const OrganizationDashboard(
          organization: {
            'id': 'test-123',
            'name': 'Sample University Org',
            'budget': 20000.0,
          },
        ),
      ),
    );
  }
}