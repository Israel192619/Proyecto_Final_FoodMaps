import 'package:flutter/material.dart';

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
    return SizedBox(
      width: 180,
      height: 110,
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        color: Colors.grey[100], // Fondo gris claro para mejor contraste
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                restaurantData['nom_rest'] ?? restaurantData['nombre_restaurante'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black, // Texto negro para contraste
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.restaurant_menu, size: 16, color: Colors.white),
                  label: const Text('Ver menú', style: TextStyle(fontSize: 12, color: Colors.white)),
                  onPressed: onMenuPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}