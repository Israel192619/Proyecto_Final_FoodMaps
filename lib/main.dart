import 'package:flutter/material.dart';
import 'login_screen.dart'; // Importa la pantalla de login
import 'register_screen.dart'; // Importa la pantalla de registro
import 'screens/cliente/maps_cli_activity.dart'; // Importa la actividad principal con el mapa

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegúrate de que los widgets estén inicializados
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
      home: const LoginScreen(), // Define LoginScreen como la pantalla principal
      routes: {
        '/register': (context) => const RegistroScreen(), // Ruta para la pantalla de registro
        '/login': (context) => const LoginScreen(), // Ruta para la pantalla de login
        '/home': (context) => const MapsCliActivity(), // Ruta para la actividad principal
      },
    );
  }
}
