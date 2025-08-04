import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../config/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<bool> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }
  //switch para mantener sesión

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      // Elimina TODOS los datos relacionados con la sesión
      await prefs.remove('auth_token');
      await prefs.remove('username');
      await prefs.remove('password');
      await prefs.remove('mantenersesion');
      await prefs.remove('userRole');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada correctamente')),
      );

      // Redirige al login y limpia completamente el stack de navegación
      Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mientras se carga el estado de autenticación
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Switch para tema claro/oscuro
                  SwitchListTile(
                    title: const Text("Modo oscuro"),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) async {
                      themeProvider.toggleTheme(value);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('map_theme', value ? 'oscuro' : 'claro');
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Acción para agregar negocio
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text("Agregar mi negocio"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _confirmLogout(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text("Cerrar Sesión"),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // No hay token → redirigir al login
          Future.microtask(() {
            print("Respuesta del servidor: No hay token de autenticación redirijiendo a login");
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          });
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
