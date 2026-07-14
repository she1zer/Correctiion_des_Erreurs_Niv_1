// ================================================================
// IMPORTS GLOBAUX
// (doivent TOUJOURS être en haut du fichier)
// ================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart' show SplashScreen;
import 'services/notification_service.dart';
export 'models/account_type.dart';

// ================================================================
// PALETTE ISITEK (COULEURS UTILISÉES PARTOUT)
// ================================================================
class IsitekColors {
  static const Color green = Color(0xFF008940);
  static const Color greenDark = Color(0xFF005930);
  static const Color greenSoft = Color(0xFFE6F4EC);
  static const Color greenBrand = Color(0xFF008940);
  static const Color darkBlueBg = Color(0xFF0F172A);
  static const Color yellow = Color(0xFFFFD700);
  static const Color bg = Color(0xFFF6FAF8);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textSoft = Color(0xFF6B7280);
  static const Color danger = Color(0xFFFF4757);
}

// ================================================================
// POINT D'ENTRÉE DE L'APPLICATION
// ================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR', null);
  await NotificationService.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const IsitekApp());
}

// ================================================================
// RACINE DE L'APP (THEME + HOME)
// ================================================================
class IsitekApp extends StatelessWidget {
  const IsitekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ISITEK Pro',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: IsitekColors.bg,
        colorSchemeSeed: IsitekColors.green,
        fontFamily: 'Roboto',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'),
      home: const SplashScreen(),
    );
  }
}

// =============================================================================
// RÉFÉRENCES (DESIGN CARTES CLIQUABLES - PARTAGÉ)
// =============================================================================
// Liste des liens des partenaires
final Map<String, String> liensPartenaires = {
  'ABB': 'https://www.abb.com/global/en',
  'FESTO': 'https://www.festo.com/us/en/',
  'FINDER': 'https://www.findernet.com/fr/belgique/',
  'LEGRAND': 'https://www.legrand.com/fr',
  'LG': 'https://www.lg.com/africa',
  'NEXANS': 'https://www.nexans.com/',
  'PHILIPS': 'https://www.philips.com/global',
  'SAMSUNG':
      'https://www.samsung.com/africa_fr/smartphones/galaxy-s26-ultra/?page=home',
  'SCHNEIDER ELECTRIC': 'https://www.se.com/',
  'SIEMENS': 'https://www.siemens.com/',
};
