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
    const MapsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.black,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Maps',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastPressed == null || now.difference(_lastPressed!) > const Duration(seconds: 2)) {
      _lastPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presiona de nuevo para salir'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }
}
