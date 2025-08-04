import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme_provider.dart';

class SettingsDuenoPage extends StatelessWidget {
  final int restauranteId;

  const SettingsDuenoPage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          SizedBox(height: 20),
          Text(
            'Configuración del Restaurante',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 20),
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
          SizedBox(height: 40),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => _cerrarSesion(context),
              child: Text('Cerrar sesión'),
            ),
          ),
        ],
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
      leading: Icon(icon),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
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

  void _cerrarSesion(BuildContext context) {
    // Implementar lógica de cierre de sesión
    Navigator.of(context).pop();
  }
}