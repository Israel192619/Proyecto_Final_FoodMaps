import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RestauranteSelectorScreen extends StatelessWidget {
  final List restaurantes;
  const RestauranteSelectorScreen({Key? key, required this.restaurantes}) : super(key: key);

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
          itemCount: restaurantes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final restaurante = restaurantes[index];
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
                                imagen,
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
                      const Icon(Icons.chevron_right, color: Colors.red, size: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
