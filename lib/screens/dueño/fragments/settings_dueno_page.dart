import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/config.dart';
import '../../../config/theme_provider.dart';

class SettingsDuenoPage extends StatelessWidget {
  final int restauranteId;

  const SettingsDuenoPage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
                constraints: BoxConstraints(maxWidth: maxWidth),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.store, size: 48, color: Colors.red.shade400),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Configuración del Restaurante',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.red.shade700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          title: const Text("Modo oscuro"),
                          value: Provider.of<ThemeProvider>(context).isDarkMode,
                          activeColor: Colors.red,
                          onChanged: (value) async {
                            Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('map_theme', value ? 'oscuro' : 'claro');
                          },
                          secondary: Icon(
                            Provider.of<ThemeProvider>(context).isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(thickness: 1.2, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        _buildSettingItem(
                          context,
                          icon: Icons.edit,
                          title: 'Editar información',
                          onTap: () => _editarInformacion(),
                        ),
                        _buildSettingItem(
                          context,
                          icon: Icons.photo,
                          title: 'Cambiar imagen',
                          onTap: () => _cambiarImagen(),
                        ),
                        _buildSettingItem(
                          context,
                          icon: Icons.location_on,
                          title: 'Actualizar ubicación',
                          onTap: () => _actualizarUbicacion(),
                        ),
                        _buildSettingItem(
                          context,
                          icon: Icons.security,
                          title: 'Seguridad',
                          onTap: () => _mostrarSeguridad(),
                        ),
                        _buildSettingItem(
                          context,
                          icon: Icons.restaurant_menu,
                          title: 'Cambiar restaurante',
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final restaurantesJson = prefs.getString('restaurantes');
                            if (restaurantesJson != null) {
                              final restaurantes = List<Map<String, dynamic>>.from(jsonDecode(restaurantesJson));
                              print('[VISTA SETTINGS] [REDIR] Redirigiendo a /restaurante_selector desde settings');
                              final selected = await Navigator.pushNamed(
                                context,
                                '/restaurante_selector',
                                arguments: restaurantes,
                              );
                              if (selected != null && selected is Map && selected['id'] != null) {
                                await prefs.setInt('restaurante_id', selected['id']);
                                await prefs.setString('restaurante_seleccionado', jsonEncode(selected));
                                print('[VISTA SETTINGS] [REDIR] Redirigiendo a /dueno_home con restaurante seleccionado desde settings');
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/dueno_home',
                                  arguments: selected,
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No se encontró la lista de restaurantes')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              textStyle: const TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _cerrarSesion(context),
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: const Text('Cerrar sesión'),
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
    );
  }

  Widget _buildSettingItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.red.withValues(alpha: 0.08),
    );
  }

  void _editarInformacion() {
    // Implementar lógica de edición
  }

  void _cambiarImagen() {
    // Implementar lógica para cambiar imagen
  }

  void _actualizarUbicacion() {
    // Implementar lógica para actualizar ubicación
  }

  void _mostrarSeguridad() {
    // Implementar lógica de seguridad
  }

  void _cerrarSesion(BuildContext context) async {
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
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      print('[VISTA SETTINGS] [REDIR] Redirigiendo a LoginScreen desde cerrar sesión en settings');
    }
  }
}
