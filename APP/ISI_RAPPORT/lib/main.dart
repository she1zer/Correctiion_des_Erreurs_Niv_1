import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const IsitekApp());
}

class IsitekApp extends StatelessWidget {
  const IsitekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISITEK - Rapport de visite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
