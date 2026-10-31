import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'core/app_colors.dart';

void main() {
  runApp(const EBrgyConnectApp());
}

class EBrgyConnectApp extends StatelessWidget {
  const EBrgyConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-BrgyConnect',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}