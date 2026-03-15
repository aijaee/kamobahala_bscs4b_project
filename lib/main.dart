import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'viewmodels/auth_viewmodel.dart';
// 1. ADD THIS IMPORT (Adjust the path if your folder names are different)
import 'views/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase connection
  await Supabase.initialize(
    // Napoleon: Standardized navigation, secured config keys, and implemented dynamic data fetching.
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
        home: const LoginScreen(),
      ),
    );
  }
}
