import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../../../config/config.dart';

String getProductImageUrl(String? imagen) {
  return AppConfig.getImageUrl(imagen);
}

class PlatosRest extends StatelessWidget {
  final List<dynamic> productos;
  final Stream<Map<String, dynamic>>? updatesStream;

  const PlatosRest({Key? key, required this.productos, this.updatesStream}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Detectar si estamos en escritorio/web o si la pantalla es lo suficientemente ancha
    final isWideScreen = screenWidth > 800 || kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

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

    // Vista responsiva: grid para pantallas anchas, lista para móviles
    return isWideScreen
      ? GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _calculateColumnCount(screenWidth),
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: productos.length,
          itemBuilder: (context, index) => _buildPlatoCard(
            context, 
            productos[index],
            isDark,
            isWideScreen,
            updatesStream,
          ),
        )
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: productos.length,
          itemBuilder: (context, index) => _buildPlatoCard(
            context,
            productos[index],
            isDark,
            isWideScreen,
            updatesStream,
          ),
        );
  }
  
  // Calcula el número de columnas según el ancho de la pantalla
  int _calculateColumnCount(double width) {
    if (width > 1400) return 4;      // Pantallas muy grandes
    if (width > 1000) return 3;      // Pantallas grandes
    return 2;                         // Pantallas medianas
  }
  
  // Construye una tarjeta de plato para cualquier layout
  Widget _buildPlatoCard(
    BuildContext context,
    Map<String, dynamic> baseProducto,
    bool isDark,
    bool isWideScreen,
    Stream<Map<String, dynamic>>? updatesStream,
  ) {
    final productId = (baseProducto['producto_id'] ?? baseProducto['id'])?.toString();

    // Stream filtrado para este producto
    final Stream<Map<String, dynamic>>? itemStream = updatesStream?.where((event) {
      final evtId = (event['producto_id'] ?? event['id'])?.toString();
      return evtId == productId;
    });

    return StreamBuilder<Map<String, dynamic>>(
      stream: itemStream,
      builder: (context, snapshot) {
        final producto = snapshot.hasData
            ? {...baseProducto, ...snapshot.data!}
            : baseProducto;

        final imageUrl = getProductImageUrl(producto['imagen']?.toString());
        final disponible = producto['disponible'] is int
            ? (producto['disponible'] == 1)
            : (producto['disponible'] == true);

        return Container(
          margin: EdgeInsets.only(bottom: isWideScreen ? 0 : 20),
          child: Card(
            elevation: 12,
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
              child: isWideScreen
                ? _buildGridCardContent(context, producto, imageUrl, disponible, isDark)
                : _buildListCardContent(context, producto, imageUrl, disponible, isDark),
            ),
          )
        );
      },
    );
  }

  // Diseño de tarjeta para grid (escritorio/pantallas anchas)
  Widget _buildGridCardContent(
    BuildContext context,
    Map<String, dynamic> producto,
    String imageUrl,
    bool disponible,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Imagen
          Expanded(
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: double.infinity,
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
                // Indicador disponibilidad
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: disponible
                        ? Colors.green.shade100.withOpacity(0.9)
                        : Colors.red.shade100.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: disponible ? Colors.green.shade300 : Colors.red.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
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
                          fontSize: 10,
                          color: disponible ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Nombre
          Text(
            producto['nombre_producto'] ?? 'Sin nombre',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Descripción
          if (producto['descripcion'] != null && producto['descripcion'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                producto['descripcion'],
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const Spacer(),

          // Precio
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Diseño de tarjeta para lista (móvil)
  Widget _buildListCardContent(
    BuildContext context,
    Map<String, dynamic> producto,
    String imageUrl,
    bool disponible,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
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
    );
  }
}
