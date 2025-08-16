import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/config.dart';

String getProductImageUrl(String? imagen) {
  if (imagen == null || imagen.isEmpty) return '';
  if (imagen.startsWith('http')) return imagen;
  return '${AppConfig.storageBaseUrl}$imagen';
}

class PlatosRest extends StatelessWidget {
  final List<dynamic> productos;

  const PlatosRest({Key? key, required this.productos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay platos disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        final imageUrl = getProductImageUrl(producto['imagen']?.toString());
        final disponible = producto['disponible'] == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 20), // Aumentado de 16 a 20
          child: Card(
            elevation: 12, // Aumentado de 8 a 12
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            color: isDark ? Colors.grey[850] : Colors.white,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isDark
                    ? LinearGradient(
                        colors: [Colors.grey[800]!, Colors.grey[850]!],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : LinearGradient(
                        colors: [Colors.white, Colors.red.shade50],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20), // Aumentado de 16 a 20
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primer contenedor: Imagen
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 100,
                          height: 100,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                                        child: Icon(
                                          Icons.food_bank,
                                          size: 50,
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                                  child: Icon(
                                    Icons.food_bank,
                                    size: 50,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Segundo contenedor: Nombre y descripción
                    Expanded(
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto['nombre_producto'] ?? 'Sin nombre',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.red.shade700,
                              ),
                            ),
                            if (producto['descripcion'] != null && producto['descripcion'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                producto['descripcion'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  height: 1.3,
                                ),
                                // Se elimina el truncado para mostrar todo el texto
                                // maxLines: 3,
                                // overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Tercer contenedor: Disponibilidad y precio
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: disponible ? Colors.green.shade100 : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: disponible ? Colors.green.shade300 : Colors.red.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      disponible ? Icons.check_circle : Icons.cancel,
                                      color: disponible ? Colors.green.shade700 : Colors.red.shade700,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      disponible ? 'Disponible' : 'No disponible',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: disponible ? Colors.green.shade700 : Colors.red.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red.shade400, Colors.red.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Bs. ${producto['precio'] ?? '0'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
