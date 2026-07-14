import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  runApp(const CaisseIsitekApp());
}

class CaisseIsitekApp extends StatelessWidget {
  const CaisseIsitekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISITEK - Gestion de Caisse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
