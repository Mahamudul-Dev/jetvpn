import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../core/routes/app_router.dart';

class AppNavigationBar extends StatefulWidget {
  const AppNavigationBar({super.key});

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
  int _selectedIndex = 0;


  void _onItemTapped(int index) {

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.goNamed(AppRoutes.home.name);
        break;
      case 1:
        context.goNamed(AppRoutes.servers.name);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: kBottomNavigationBarHeight,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface, // Matches Gmail base
        indicatorColor: Theme.of(
          context,
        ).colorScheme.primaryContainer.withAlpha(50), // M3 style
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }
          return IconThemeData(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Ionicons.home_outline),
            selectedIcon: Icon(Ionicons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Ionicons.location_outline),
            selectedIcon: Icon(Ionicons.location),
            label: 'Servers',
          ),
        ],
      ),
    );
  }
}
