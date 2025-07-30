import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Importa la pantalla de login
import 'screens/register_screen.dart'; // Importa la pantalla de registro
import 'screens/maps_cli_activity.dart'; // Importa la actividad principal con el mapa

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Asegúrate de que los widgets estén inicializados
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapsCliActivity(), // Define LoginScreen como la pantalla principal
      routes: {
        // ...otras rutas...
        '/register': (context) => const RegistroScreen(), // Ruta para la pantalla de registro
      },
    );
  }
}
