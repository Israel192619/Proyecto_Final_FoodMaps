import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../config/theme_provider.dart';
import '../../../config/config.dart';
import '../../publica/new_restaurante.dart'; // Agrega este import

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
      // Mostrar loader modal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      // Guarda el modo oscuro antes de limpiar
      final mapTheme = prefs.getString('map_theme');
      // Llamada a la API para cerrar sesión
      if (token != null && token.isNotEmpty) {
        try {
          final response = await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          print('Logout API status: ${response.statusCode}');
        } catch (e) {
          print('Error al llamar logout: $e');
        }
      }
      await prefs.clear();
      // Restaurar el modo oscuro después de limpiar
      if (mapTheme != null) {
        await prefs.setString('map_theme', mapTheme);
        // Fuerza el tema oscuro si el valor es 'oscuro'
        if (mapTheme == 'oscuro') {
          Provider.of<ThemeProvider>(context, listen: false).setDarkMode(true);
        } else {
          Provider.of<ThemeProvider>(context, listen: false).setDarkMode(false);
        }
      }
      // Cerrar loader modal
      Navigator.of(context, rootNavigator: true).pop();
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.black, Colors.grey.shade900]
                      : [Colors.white, Colors.red.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double maxWidth = constraints.maxWidth < 500 ? constraints.maxWidth * 0.98 : 420;
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth,
                        ),
                        child: Card(
                          elevation: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_pin, size: 64, color: Colors.red.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  "Ajustes de Usuario",
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.red.shade700,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                SwitchListTile(
                                  title: const Text("Modo oscuro"),
                                  value: themeProvider.isDarkMode,
                                  activeColor: Colors.red,
                                  onChanged: (value) async {
                                    themeProvider.toggleTheme(value);
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setString('map_theme', value ? 'oscuro' : 'claro');
                                  },
                                  secondary: Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Divider(thickness: 1.2, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const NewRestauranteScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add_business),
                                    label: const Text("Agregar mi negocio"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      textStyle: const TextStyle(fontSize: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _confirmLogout(context),
                                    icon: const Icon(Icons.logout, color: Colors.red),
                                    label: const Text("Cerrar Sesión"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red, width: 1.5),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      textStyle: const TextStyle(fontSize: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
