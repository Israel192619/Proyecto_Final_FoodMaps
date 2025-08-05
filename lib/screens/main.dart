import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dueño/new_restaurante.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'cliente/maps_cli_activity.dart';
import 'dueño/maps_due_activity.dart';
import 'SplashScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../config/theme_provider.dart';
import '../config/app_themes.dart';
import 'dueño/restaurante_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/home': (context) => const AuthWrapper(),
            '/register': (context) => const RegistroScreen(),
            '/login': (context) => const LoginScreen(),
            '/mapsCliActivity': (context) => const MapsCliActivity(),
            '/mapsDueActivity': (context) => const MapsDueActivity(restauranteId: 0),
            '/new_restaurante': (context) => const NewRestauranteScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/dueno_home') {
              final restaurante = settings.arguments;
              int restauranteId = 0;
              if (restaurante is Map && restaurante['restaurante_id'] != null) {
                restauranteId = restaurante['restaurante_id'] is int
                    ? restaurante['restaurante_id']
                    : int.tryParse(restaurante['restaurante_id'].toString()) ?? 0;
              }
              return MaterialPageRoute(
                builder: (context) => MapsDueActivity(restauranteId: restauranteId),
                settings: settings,
              );
            }
            // Soporte para restaurante_selector con argumentos
            if (settings.name == '/restaurante_selector') {
              final restaurantes = settings.arguments as List;
              return MaterialPageRoute(
                builder: (context) => RestauranteSelectorScreen(restaurantes: restaurantes),
                settings: settings,
              );
            }
            return null;
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _checkAuthAndRestaurantStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final authData = snapshot.data ?? {};
        final isAuthenticated = authData['authenticated'] ?? false;
        final keepSession = authData['keepSession'] ?? false;
        final hasCredentials = authData['hasCredentials'] ?? false;
        final hasRestaurant = authData['hasRestaurant'] ?? false;
        final userRole = authData['userRole'] ?? 1;
        final forcedLogout = authData['forcedLogout'] ?? false;
        final restaurantes = authData['restaurantes'] ?? [];
        final restauranteId = authData['restauranteId'];

        // Si fue un logout forzado, ir al login
        if (forcedLogout) {
          return const LoginScreen();
        }

        if (!isAuthenticated || (!keepSession && !hasCredentials)) {
          return const LoginScreen();
        }

        // Lógica de redirección basada en rol y estado del restaurante
        if (userRole == 2) { // Dueño
          if (!hasRestaurant) {
            return const NewRestauranteScreen();
          }
          // Si hay varios restaurantes y no hay uno seleccionado, ir al selector
          if (restaurantes is List && restaurantes.length > 1 && restauranteId == null) {
            // Redirige al selector de restaurantes
            return RestauranteSelectorScreen(restaurantes: restaurantes);
          }
          // Si hay uno seleccionado, ir directo al home del dueño
          if (restauranteId != null) {
            return MapsDueActivity(restauranteId: restauranteId);
          }
          // Si solo hay uno, ir directo
          if (restaurantes is List && restaurantes.length == 1) {
            return MapsDueActivity(restauranteId: restaurantes[0]['id']);
          }
          // Fallback
          return const NewRestauranteScreen();
        } else { // Cliente
          return const MapsCliActivity();
        }
      },
    );
  }

  Future<Map<String, dynamic>> _checkAuthAndRestaurantStatus() async {
    // Forzar que el splash se muestre al menos 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final keepSession = prefs.getBool('mantenersesion') ?? false;
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final userRole = prefs.getInt('userRole') ?? 1;
    final forcedLogout = prefs.getBool('forcedLogout') ?? false;
    final restauranteId = prefs.getInt('restaurante_id');

    // Resetear el estado de forcedLogout para futuros inicios
    if (forcedLogout) {
      await prefs.setBool('forcedLogout', false);
    }

    // Verificar autenticación básica
    if (token == null || token.isEmpty) {
      return {
        'authenticated': false,
        'keepSession': keepSession,
        'hasCredentials': username != null && password != null,
        'userRole': userRole,
        'hasRestaurant': false,
        'forcedLogout': forcedLogout,
      };
    }

    // Para dueños, verificar si tienen restaurante y cuántos
    if (userRole == 2) {
      try {
        final response = await http.get(
          Uri.parse('https://tuapi.com/api/restaurantes/verificar'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final restaurantes = data['restaurantes'] ?? [];
          return {
            'authenticated': true,
            'keepSession': keepSession,
            'hasCredentials': username != null && password != null,
            'userRole': userRole,
            'hasRestaurant': data['tieneRestaurante'] ?? false,
            'forcedLogout': forcedLogout,
            'restaurantes': restaurantes,
            'restauranteId': restauranteId,
          };
        }
      } catch (e) {
        print('Error al verificar restaurante: $e');
      }
    }

    return {
      'authenticated': token.isNotEmpty,
      'keepSession': keepSession,
      'hasCredentials': username != null && password != null,
      'userRole': userRole,
      'hasRestaurant': userRole == 1,
      'forcedLogout': forcedLogout,
    };
  }
}
