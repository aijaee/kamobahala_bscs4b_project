import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/projects_viewmodel.dart';
import 'viewmodels/tasks_viewmodel.dart';
import 'viewmodels/financial_viewmodel.dart';
import 'views/auth/login_screen.dart';

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
        ChangeNotifierProvider(create: (_) => ProjectsViewModel()),
        ChangeNotifierProvider(create: (_) => TasksViewModel()),
        ChangeNotifierProvider(create: (_) => FinancialViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Kamo Bahala",
        home: const LoginScreen(),
      ),
    );
  }
}