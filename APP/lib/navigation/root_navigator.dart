import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart' show IsitekColors;
import '../screens/client/client_dashboard_screen.dart';
import '../screens/client/client_demandes_screen.dart';
import '../screens/client/client_messages_screen.dart';
import '../screens/client/client_profile_screen.dart';

class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => RootNavigatorState();
}

class RootNavigatorState extends State<RootNavigator> {
  int index = 0;

  void setIndex(int i) {
    setState(() {
      index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ClientDashboardScreen(),  // 0 : ACCUEIL
      const ClientDemandesScreen(),   // 1 : DEMANDES
      const ClientMessagesScreen(),   // 2 : MESSAGES
      const ClientProfileScreen(),    // 3 : PROFIL
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: 350.ms,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: pages[index],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 70,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: IsitekColors.green.withOpacity(0.12),
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: IsitekColors.green),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded, color: IsitekColors.green),
              label: 'Demandes',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded, color: IsitekColors.green),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: IsitekColors.green),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
