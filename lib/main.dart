import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/publica/new_restaurante.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/cliente/maps_cli_activity.dart';
import 'screens/dueño/maps_due_activity.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'config/theme_provider.dart';
import 'config/app_themes.dart';
import 'screens/dueño/restaurante_selector.dart';

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
          title: 'foodmaps',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const AuthWrapper());
              case '/login':
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case '/register':
                return MaterialPageRoute(builder: (_) => const RegistroScreen());
              case '/new_restaurante':
                return MaterialPageRoute(builder: (_) => const NewRestauranteScreen());
              case '/restaurante_selector':
                final restaurantes = settings.arguments as List;
                return MaterialPageRoute(
                  builder: (_) => RestauranteSelectorScreen(restaurantes: restaurantes),
                );
              case '/dueno_home':
                final restaurante = settings.arguments;
                int restauranteId = 0;
                if (restaurante is Map && restaurante['id'] != null) {
                  restauranteId = restaurante['id'] is int
                      ? restaurante['id']
                      : int.tryParse(restaurante['id'].toString()) ?? 0;
                }
                return MaterialPageRoute(
                  builder: (_) => MapsDueActivity(restauranteId: restauranteId),
                );
              case '/mapsCliActivity':
                return MaterialPageRoute(builder: (_) => const MapsCliActivity());
              default:
                return MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Center(child: Text('Ruta no encontrada: \'${settings.name}\'')),
                  ),
                );
            }
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Map<String, dynamic>> _getAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final keepSession = prefs.getBool('mantenersesion') ?? false;
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    final userRole = prefs.getInt('userRole') ?? 1;
    final forcedLogout = prefs.getBool('forcedLogout') ?? false;
    final restauranteId = prefs.getInt('restaurante_id');
    final restaurantesJson = prefs.getString('restaurantes');
    List restaurantes = [];
    if (restaurantesJson != null && restaurantesJson.isNotEmpty) {
      try {
        restaurantes = List<Map<String, dynamic>>.from(jsonDecode(restaurantesJson));
      } catch (_) {}
    }

    // Imprimir logs de diagnóstico para depurar problemas de sesión
    print('[AUTH_WRAPPER] Estado actual: token=${token != null}, mantenersesion=$keepSession');
    print('[AUTH_WRAPPER] Credenciales: username=${username != null}, password=${password != null}');

    return {
      'token': token,
      'keepSession': keepSession,
      'username': username,
      'password': password,
      'userRole': userRole,
      'forcedLogout': forcedLogout,
      'restauranteId': restauranteId,
      'restaurantes': restaurantes,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAuthState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Loader personalizado con logo
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage('assets/icons/iconFoodMaps.png'),
                    width: 120,
                    height: 120,
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }
        final auth = snapshot.data!;
        final token = auth['token'];
        final keepSession = auth['keepSession'];
        final username = auth['username'];
        final password = auth['password'];
        final userRole = auth['userRole'];
        final forcedLogout = auth['forcedLogout'];
        final restauranteId = auth['restauranteId'];
        final restaurantes = auth['restaurantes'];

        // --- Lógica de navegación robusta ---
        if (forcedLogout) {
          print('[VISTA AUTHWRAPPER] forcedLogout, mostrando LoginScreen');
          print('[VISTA AUTHWRAPPER] [REDIR] Redirigiendo a LoginScreen por forcedLogout');
          return const LoginScreen();
        }

        // Verificar si tenemos un token válido
        if (token == null || token.isEmpty) {
          print('[VISTA AUTHWRAPPER] No hay token, mostrando LoginScreen');
          print('[VISTA AUTHWRAPPER] [REDIR] Redirigiendo a LoginScreen por falta de token');
          return const LoginScreen();
        }

        // Si no mantenemos sesión, verificar que tengamos credenciales para auto-login
        if (!keepSession && (username == null || password == null)) {
          print('[VISTA AUTHWRAPPER] No mantener sesión y sin credenciales, mostrando LoginScreen');
          print('[VISTA AUTHWRAPPER] [REDIR] Redirigiendo a LoginScreen por no mantener sesión');
          return const LoginScreen();
        }

        // A partir de aquí sabemos que hay token y que o bien mantenemos sesión o tenemos credenciales

        // Si es dueño (rol 2)
        if (userRole == 2) {
          if (restaurantes.isEmpty) {
            print('[VISTA AUTHWRAPPER] Dueño sin restaurantes, mostrando NewRestauranteScreen');
            print('[VISTA AUTHWRAPPER] [REDIR] Redirigiendo a NewRestauranteScreen por dueño sin restaurantes');
            return const NewRestauranteScreen();
          }
          if (restaurantes.length > 1 && (restauranteId == null || restauranteId == 0)) {
            print('[VISTA AUTHWRAPPER] Dueño con varios restaurantes, mostrando selector');
            print('[VISTA AUTHWRAPPER] [REDIR] Redirigiendo a RestauranteSelectorScreen por dueño con varios restaurantes');
            return RestauranteSelectorScreen(restaurantes: restaurantes);
          }
          // Si solo hay uno o ya hay uno seleccionado
          final selectedRestId = restauranteId ?? (restaurantes.isNotEmpty ? restaurantes[0]['id'] : null);
          if (selectedRestId != null && selectedRestId != 0) {
            print('[VISTA AUTHWRAPPER] Dueño con restaurante seleccionado, mostrando MapsDueActivity');
            print('[VISTA AUTHWRAPPER] [REDIR] Redirigiendo a MapsDueActivity por dueño con restaurante seleccionado');
            return MapsDueActivity(restauranteId: selectedRestId);
          }
        }
        // Cliente
        print('[VISTA AUTHWRAPPER] Cliente autenticado, mostrando MapsCliActivity');
        print('[VISTA AUTHWRAPPER] [REDIR] Redirigiendo a MapsCliActivity por cliente autenticado');
        return const MapsCliActivity();
      },
    );
  }
}

// Recomendación: Navega entre vistas principales usando pushReplacementNamed o pushNamedAndRemoveUntil
// para evitar que se apilen LoginScreen, RegistroScreen y NewRestauranteScreen en el stack.
// Ejemplo:
// Navigator.pushReplacementNamed(context, '/login');
// Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
