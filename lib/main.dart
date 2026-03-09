import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'views/auth/login_screen.dart';

void main() {
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