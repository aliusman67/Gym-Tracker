/// Bottom-navigation shell for the 5 main tabs.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _items = [
    (icon: Icons.dashboard_outlined, active: Icons.dashboard, label: 'Home'),
    (icon: Icons.auto_awesome, active: Icons.auto_awesome, label: 'Quest'),
    (icon: Icons.fitness_center_outlined, active: Icons.fitness_center, label: 'Program'),
    (icon: Icons.restaurant_menu_outlined, active: Icons.restaurant_menu, label: 'Nutrisi'),
    (icon: Icons.trending_up_outlined, active: Icons.trending_up, label: 'Progres'),
    (icon: Icons.settings_outlined, active: Icons.settings, label: 'Setting'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
        backgroundColor: const Color(0xFF17191E),
        indicatorColor: const Color(0xFFE5484D).withValues(alpha: 0.18),
        destinations: [
          for (final it in _items)
            NavigationDestination(
              icon: Icon(it.icon),
              selectedIcon: Icon(it.active),
              label: it.label,
            ),
        ],
      ),
    );
  }
}
