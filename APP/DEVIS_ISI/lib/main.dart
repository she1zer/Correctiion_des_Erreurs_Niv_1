import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/devis_provider.dart';
import 'screens/devis_form_screen.dart';
import 'utils/app_theme.dart';

/// Point d'entrée de l'application "Devis ISITEK".
///
/// Met en place le [DevisProvider] au sommet de l'arbre de widgets afin
/// que toute modification du devis (en-tête, produits, conditions de
/// règlement) déclenche une mise à jour instantanée de l'aperçu et des
/// totaux, conformément à l'exigence de calcul en temps réel.
void main() {
  runApp(const DevisIsitekApp());
}

class DevisIsitekApp extends StatelessWidget {
  const DevisIsitekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DevisProvider(),
      child: MaterialApp(
        title: 'Devis ISITEK',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const DevisFormScreen(),
      ),
    );
  }
}
