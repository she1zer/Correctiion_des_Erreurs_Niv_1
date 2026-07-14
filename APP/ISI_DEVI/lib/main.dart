// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models.dart';
import 'screens/form_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const ISITEKApp());
}

class ISITEKApp extends StatelessWidget {
  const ISITEKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISITEK Devis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEFF6FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF93C5FD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF93C5FD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFF1E3A8A), width: 2),
          ),
          labelStyle: const TextStyle(
              color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      home: FormScreen(
        devis: DevisData(
          date: _todayString(),
          lignes: [
            LigneArticle(id: '1', unite: 'U'),
            LigneArticle(id: '2', unite: 'U'),
            LigneArticle(id: '3', unite: 'U'),
          ],
        ),
      ),
    );
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }
}
