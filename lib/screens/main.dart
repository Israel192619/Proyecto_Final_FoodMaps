import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'cliente/maps_cli_activity.dart';
import 'dueño/maps_due_activity.dart';
import 'SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/register': (context) => const RegistroScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MapsCliActivity(),
        '/home_dueno': (context) => const MapsDueActivity(restauranteId: 0,),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final isAuthenticated = snapshot.data?['authenticated'] ?? false;
        final keepSession = snapshot.data?['keepSession'] ?? false;
        final hasCredentials = snapshot.data?['hasCredentials'] ?? false;

        if (isAuthenticated && (keepSession || hasCredentials)) {
          return const MapsCliActivity();
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  Future<Map<String, dynamic>> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final keepSession = prefs.getBool('mantenersesion') ?? false;
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    print('Datos en SharedPreferences al iniciar:');
    print('Token: $token');
    print('Mantener sesión: $keepSession');
    print('Username: $username');
    print('Password: $password');

    return {
      'authenticated': token != null && token.isNotEmpty,
      'keepSession': keepSession,
      'hasCredentials': username != null && password != null,
    };
  }
}

  Future<bool> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }
