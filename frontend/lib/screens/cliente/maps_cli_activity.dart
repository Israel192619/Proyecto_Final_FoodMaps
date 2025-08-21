import 'package:flutter/material.dart';
import 'dart:async';
import 'fragments/maps_page.dart';
import 'fragments/settings_page.dart';

class MapsCliActivity extends StatefulWidget {
  const MapsCliActivity({super.key});

  @override
  State<MapsCliActivity> createState() => _MapsCliActivityState();
}

class _MapsCliActivityState extends State<MapsCliActivity> {
  int _selectedIndex = 0;
  DateTime? _lastPressed;

  final List<Widget> _pages = [
    MapsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false, // Cambiar a false para interceptar el botón atrás
      onPopInvokedWithResult: (didPop, popAction) async {
        if (!didPop) {
          final result = await _onWillPop();
          if (result) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.red,
              unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined, size: 28),
                  activeIcon: Icon(Icons.map, size: 30),
                  label: 'Mapa',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined, size: 28),
                  activeIcon: Icon(Icons.settings, size: 30),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la aplicación?'),
        content: const Text('¿Estás seguro que quieres salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }
}
