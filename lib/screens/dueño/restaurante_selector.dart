import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/config.dart'; // Agrega este import

String getRestauranteImageUrl(String? imagen) {
  if (imagen == null || imagen.isEmpty) return '';
  final url = '${AppConfig.storageBaseUrl}$imagen';
  print('[SELECTOR][LOGO] Ruta completa de imagen: $url');
  return url;
}

class RestauranteSelectorScreen extends StatefulWidget {
  final List restaurantes;
  const RestauranteSelectorScreen({Key? key, required this.restaurantes}) : super(key: key);

  @override
  State<RestauranteSelectorScreen> createState() => _RestauranteSelectorScreenState();
}

class _RestauranteSelectorScreenState extends State<RestauranteSelectorScreen> {
  List _restaurantes = [];

  @override
  void initState() {
    super.initState();
    _restaurantes = List.from(widget.restaurantes);
  }

  Future<void> _eliminarRestaurante(int restauranteId, String nombreRestaurante) async {
    // Mostrar diálogo de confirmación
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro que quieres eliminar el restaurante "$nombreRestaurante"?\n\nEsta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true) return;

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final url = AppConfig.getApiUrl(AppConfig.eliminarRestauranteEndpoint(restauranteId));
      print('[SELECTOR] URL DELETE restaurante: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[SELECTOR] Respuesta DELETE restaurante statusCode: ${response.statusCode}');
      print('[SELECTOR] Respuesta DELETE restaurante body: ${response.body}');

      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        // Eliminar de la lista local
        setState(() {
          _restaurantes.removeWhere((r) => r['id'] == restauranteId);
        });

        // Actualizar SharedPreferences si es necesario
        final restauranteIdActual = prefs.getInt('restaurante_id');
        if (restauranteIdActual == restauranteId) {
          await prefs.remove('restaurante_id');
          await prefs.remove('restaurante_seleccionado');
          await prefs.setBool('hasRestaurant', false);
        }

        // Actualizar lista de restaurantes en SharedPreferences
        await prefs.setString('restaurantes', jsonEncode(_restaurantes));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restaurante "$nombreRestaurante" eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Si no quedan restaurantes, redirigir a new_restaurante
          if (_restaurantes.isEmpty) {
            Navigator.pushReplacementNamed(context, '/new_restaurante');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar restaurante: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();

      print('[SELECTOR] Error al eliminar restaurante: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión al eliminar restaurante'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un restaurante'),
        backgroundColor: isDark ? Colors.black : Colors.red.shade700,
        elevation: 2,
      ),
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
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          itemCount: _restaurantes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final restaurante = _restaurantes[index];
            final imagen = restaurante['imagen'];
            final nombre = restaurante['nombre_restaurante'] ?? 'Restaurante';
            final tematica = restaurante['tematica'] ?? '';
            final ubicacion = restaurante['ubicacion'] ?? '';
            final contadorVistas = restaurante['contador_vistas'] ?? 0;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              color: isDark ? Colors.grey[900] : Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  print('[VISTA SELECTOR] Tap en restaurante_selector: id=${restaurante['id']}');
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('restaurante_id', restaurante['id']);
                  await prefs.setString('restaurante_seleccionado', jsonEncode(restaurante));
                  print('[VISTA SELECTOR] Guardado en SharedPreferences: restaurante_id=${restaurante['id']}, restaurante_seleccionado=${jsonEncode(restaurante)}');
                  final token = prefs.getString('auth_token');
                  print('[VISTA SELECTOR] Token actual en SharedPreferences: $token');
                  print('[VISTA SELECTOR] [REDIR] Redirigiendo a /dueno_home desde restaurante_selector');
                  Navigator.pushReplacementNamed(
                    context,
                    '/dueno_home',
                    arguments: restaurante,
                  );
                  print('[VISTA SELECTOR] Redirigido a /dueno_home con restaurante: $restaurante');
                },
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imagen != null && imagen.toString().isNotEmpty
                            ? Image.network(
                                getRestauranteImageUrl(imagen),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 32, color: Colors.grey),
                                    ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 32, color: Colors.grey),
                              ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.red.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (tematica.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  tematica,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      ubicacion,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.grey[400] : Colors.grey[800],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.remove_red_eye, size: 15, color: Colors.red),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$contadorVistas vistas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.grey[400] : Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _eliminarRestaurante(restaurante['id'], nombre),
                            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 28),
                            tooltip: 'Eliminar restaurante',
                          ),
                          const Icon(Icons.chevron_right, color: Colors.red, size: 24),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/new_restaurante');
        },
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar Restaurante'),
        elevation: 8,
      ),
    );
  }
}
