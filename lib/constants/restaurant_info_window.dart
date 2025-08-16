import 'package:flutter/material.dart';
import '../config/config.dart';
import '../screens/publica/Menu_Restaurante.dart';

String getRestauranteImageUrl(String? imagen) {
  if (imagen == null || imagen.isEmpty) return '';
  if (imagen.startsWith('http')) return imagen;
  final url = '${AppConfig.storageBaseUrl}$imagen';
  print('[INFO_WINDOW][LOGO] Ruta completa de imagen: $url');
  return url;
}

class RestaurantInfoWindow extends StatelessWidget {
  final Map<String, dynamic> restaurantData;
  final VoidCallback? onMenuPressed;

  const RestaurantInfoWindow({
    Key? key,
    required this.restaurantData,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = getRestauranteImageUrl(restaurantData['imagen']?.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF232526) : Colors.grey[100]!;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color buttonColor = isDark ? Colors.red.shade700 : Colors.black;
    final Color buttonTextColor = Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxButtonWidth = constraints.maxWidth < 180 ? constraints.maxWidth : 140;
        return SizedBox(
          width: constraints.maxWidth,
          height: 130,
          child: Card(
            elevation: 6,
            margin: EdgeInsets.zero,
            color: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    restaurantData['nom_rest'] ?? restaurantData['nombre_restaurante'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 70,
                                  height: 70,
                                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                                  child: Icon(Icons.image, size: 40, color: isDark ? Colors.white54 : Colors.grey),
                                ),
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            child: Icon(Icons.image, size: 40, color: isDark ? Colors.white54 : Colors.grey),
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    width: maxButtonWidth,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size(80, 32),
                        maximumSize: Size(maxButtonWidth, 32),
                      ),
                      icon: Icon(Icons.restaurant_menu, size: 16, color: buttonTextColor),
                      label: Text('Ver menú', style: TextStyle(fontSize: 12, color: buttonTextColor)),
                      onPressed: () {
                        print('[INFO_WINDOW] Botón Ver menú presionado');

                        // Navega directamente sin depender del callback
                        final int restaurantId = restaurantData['restaurante_id'] is int
                            ? restaurantData['restaurante_id']
                            : (restaurantData['id'] is int
                                ? restaurantData['id']
                                : int.tryParse(restaurantData['restaurante_id']?.toString() ??
                                    restaurantData['id']?.toString() ?? '0') ?? 0);
                        final String name = restaurantData['nom_rest'] ??
                                          restaurantData['nombre_restaurante'] ?? '';
                        final String phone = restaurantData['celular']?.toString() ?? '';
                        final String imageUrlParam = restaurantData['imagen']?.toString() ?? '';

                        print('[INFO_WINDOW] Navegando directamente a menú: restaurantId=$restaurantId, name=$name');

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MenuRestaurante(
                              restaurantId: restaurantId,
                              name: name,
                              phone: phone,
                              imageUrl: imageUrlParam,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}