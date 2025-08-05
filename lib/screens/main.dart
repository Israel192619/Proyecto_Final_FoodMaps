import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dueño/new_restaurante.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'cliente/maps_cli_activity.dart';
import 'dueño/maps_due_activity.dart';
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
              } else if (restaurante is Map && restaurante['id'] != null) {
                restauranteId = restaurante['id'] is int
                    ? restaurante['id']
                    : int.tryParse(restaurante['id'].toString()) ?? 0;
              }
              return MaterialPageRoute(
                builder: (context) => MapsDueActivity(restauranteId: restauranteId),
                settings: settings,
              );
            }
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
          print('[AUTHWRAPPER] Esperando datos de autenticación...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authData = snapshot.data ?? {};
        final isAuthenticated = authData['authenticated'] ?? false;
        final keepSession = authData['keepSession'] ?? false;
        final hasCredentials = authData['hasCredentials'] ?? false;
        final userRole = authData['userRole'] ?? 1;
        final forcedLogout = authData['forcedLogout'] ?? false;
        final restaurantes = authData['restaurantes'] ?? [];
        final restauranteId = authData['restauranteId'];
        final restauranteSeleccionado = authData['restauranteSeleccionado'];

        print('[AUTHWRAPPER] Datos: '
            'isAuthenticated=$isAuthenticated, keepSession=$keepSession, hasCredentials=$hasCredentials, '
            'userRole=$userRole, forcedLogout=$forcedLogout, restauranteId=$restauranteId, restaurantes=$restaurantes, restauranteSeleccionado=$restauranteSeleccionado');

        if (forcedLogout) {
          print('[AUTHWRAPPER] Redirigiendo a LoginScreen por forcedLogout');
          return const LoginScreen();
        }

        if (!isAuthenticated || (!keepSession && !hasCredentials)) {
          print('[AUTHWRAPPER] Redirigiendo a LoginScreen por no autenticado o sin credenciales');
          return const LoginScreen();
        }

        // --- Lógica para dueño ---
        if (userRole == 2) {
          print('[AUTHWRAPPER] [DUEÑO] Entrando a lógica de dueño');
          Map<String, dynamic>? restauranteSeleccionadoLista;
          print('[AUTHWRAPPER] [DUEÑO] restaurantes: $restaurantes');
          print('[AUTHWRAPPER] [DUEÑO] restauranteId: $restauranteId');
          print('[AUTHWRAPPER] [DUEÑO] restauranteSeleccionado: $restauranteSeleccionado');
          if (restaurantes is List && restaurantes.isNotEmpty && restauranteId != null) {
            try {
              restauranteSeleccionadoLista = restaurantes.firstWhere(
                (r) => r['id'] == restauranteId,
                orElse: () {
                  print('[AUTHWRAPPER] [DUEÑO] orElse de firstWhere ejecutado');
                  return <String, dynamic>{};
                },
              );
              print('[AUTHWRAPPER] [DUEÑO] restauranteSeleccionadoLista: $restauranteSeleccionadoLista');
              if (restauranteSeleccionadoLista != null && restauranteSeleccionadoLista.isNotEmpty) {
                print('[AUTHWRAPPER] Dueño: restaurante seleccionado encontrado en lista, id=$restauranteId');
                return MapsDueActivity(restauranteId: restauranteId);
              }
            } catch (e) {
              print('[AUTHWRAPPER] [DUEÑO] Excepción en firstWhere: $e');
              restauranteSeleccionadoLista = null;
            }
            if (restauranteSeleccionado != null && restauranteSeleccionado['id'] == restauranteId) {
              print('[AUTHWRAPPER] Dueño: restaurante seleccionado solo en SharedPreferences, id=$restauranteId');
              return MapsDueActivity(restauranteId: restauranteId);
            } else {
              print('[AUTHWRAPPER] Dueño: restauranteId $restauranteId no está en la lista ni en prefs');
            }
          }
          if (restaurantes is List && restaurantes.length > 1 && restauranteId == null) {
            print('[AUTHWRAPPER] Dueño: varios restaurantes y ninguno seleccionado, mostrando selector');
            return RestauranteSelectorScreen(restaurantes: restaurantes);
          }
          if (restaurantes is List && restaurantes.length == 1) {
            print('[AUTHWRAPPER] Dueño: solo un restaurante, id=${restaurantes[0]['id']}');
            return MapsDueActivity(restauranteId: restaurantes[0]['id']);
          }
          print('[AUTHWRAPPER] Dueño: no tiene restaurantes, mostrando NewRestauranteScreen');
          return const NewRestauranteScreen();
        }
        print('[AUTHWRAPPER] Cliente: mostrando MapsCliActivity');
        return const MapsCliActivity();
      },
    );
  }

  Future<Map<String, dynamic>> _checkAuthAndRestaurantStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final keepSession = prefs.getBool('mantenersesion') ?? false;
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final userRole = prefs.getInt('userRole') ?? 1;
    final forcedLogout = prefs.getBool('forcedLogout') ?? false;
    int? restauranteId = prefs.getInt('restaurante_id');

    print('[AUTHWRAPPER] [CHECK_AUTH] token=$token, keepSession=$keepSession, username=$username, '
        'userRole=$userRole, forcedLogout=$forcedLogout, restauranteId=$restauranteId');

    if (forcedLogout) {
      await prefs.setBool('forcedLogout', false);
      print('[AUTHWRAPPER] [CHECK_AUTH] forcedLogout detectado, limpiando flag');
    }

    if (token == null || token.isEmpty) {
      print('[AUTHWRAPPER] [CHECK_AUTH] No hay token, usuario no autenticado');
      return {
        'authenticated': false,
        'keepSession': keepSession,
        'hasCredentials': username != null && password != null,
        'userRole': userRole,
        'hasRestaurant': false,
        'forcedLogout': forcedLogout,
      };
    }

    List restaurantes = [];
    Map<String, dynamic>? restauranteSeleccionado;
    if (userRole == 2) {
      bool backendOk = false;
      try {
        final response = await http.get(
          Uri.parse('https://tuapi.com/api/restaurantes/verificar'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('[AUTHWRAPPER] [CHECK_AUTH] Respuesta backend restaurantes/verificar: status=${response.statusCode}, body=${response.body}');

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            restaurantes = data['restaurantes'] ?? [];
            print('[AUTHWRAPPER] [CHECK_AUTH] Restaurantes obtenidos del backend: $restaurantes');
            backendOk = true;
          } catch (e) {
            print('[AUTHWRAPPER] [CHECK_AUTH] Error al decodificar JSON del backend: $e');
          }
        }
      } catch (e) {
        print('[AUTHWRAPPER] [CHECK_AUTH] Excepción al verificar restaurante: $e');
      }

      if (!backendOk || restaurantes.isEmpty) {
        final restaurantesJson = prefs.getString('restaurantes');
        print('[AUTHWRAPPER] [CHECK_AUTH] Restaurantes backend vacíos o error, buscando en SharedPreferences...');
        if (restaurantesJson != null && restaurantesJson.isNotEmpty) {
          try {
            restaurantes = List<Map<String, dynamic>>.from(jsonDecode(restaurantesJson));
            print('[AUTHWRAPPER] [CHECK_AUTH] Restaurantes recuperados de SharedPreferences: $restaurantes');
          } catch (e) {
            print('[AUTHWRAPPER] [CHECK_AUTH] Error al decodificar restaurantes de SharedPreferences: $e');
          }
        } else {
          print('[AUTHWRAPPER] [CHECK_AUTH] No hay restaurantes guardados en SharedPreferences');
        }
      }

      if (restauranteId != null) {
        final restauranteSelJson = prefs.getString('restaurante_seleccionado');
        print('[AUTHWRAPPER] [CHECK_AUTH] Buscando restaurante_seleccionado en SharedPreferences...');
        if (restauranteSelJson != null && restauranteSelJson.isNotEmpty) {
          try {
            restauranteSeleccionado = jsonDecode(restauranteSelJson);
            print('[AUTHWRAPPER] [CHECK_AUTH] Restaurante seleccionado recuperado de SharedPreferences: $restauranteSeleccionado');
          } catch (e) {
            print('[AUTHWRAPPER] [CHECK_AUTH] Error al decodificar restaurante_seleccionado: $e');
          }
        } else {
          print('[AUTHWRAPPER] [CHECK_AUTH] No hay restaurante_seleccionado guardado en SharedPreferences');
        }
      }

      if (restauranteId != null &&
          !(restaurantes.any((r) => r['id'] == restauranteId))) {
        print('[AUTHWRAPPER] [CHECK_AUTH] restaurante_id guardado ($restauranteId) no existe en la lista, eliminando');
        restauranteId = null;
        await prefs.remove('restaurante_id');
      }
      print('[AUTHWRAPPER] [CHECK_AUTH] Dueño autenticado, restaurantes=$restaurantes, restauranteId=$restauranteId, restauranteSeleccionado=$restauranteSeleccionado');
      return {
        'authenticated': true,
        'keepSession': keepSession,
        'hasCredentials': username != null && password != null,
        'userRole': userRole,
        'forcedLogout': forcedLogout,
        'restaurantes': restaurantes,
        'restauranteId': restauranteId,
        'restauranteSeleccionado': restauranteSeleccionado,
      };
    }

    print('[AUTHWRAPPER] [CHECK_AUTH] Usuario no dueño o error, autenticado=${token != null && token.isNotEmpty}');
    return {
      'authenticated': token != null && token.isNotEmpty,
      'keepSession': keepSession,
      'hasCredentials': username != null && password != null,
      'userRole': userRole,
      'forcedLogout': forcedLogout,
    };
  }
}
