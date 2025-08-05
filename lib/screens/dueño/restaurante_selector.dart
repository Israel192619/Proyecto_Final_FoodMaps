import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestauranteSelectorScreen extends StatelessWidget {
  final List restaurantes;
  const RestauranteSelectorScreen({Key? key, required this.restaurantes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona un restaurante')),
      body: ListView.separated(
        itemCount: restaurantes.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final restaurante = restaurantes[index];
          return ListTile(
            leading: const Icon(Icons.restaurant),
            title: Text(restaurante['nombre_restaurante'] ?? 'Restaurante'),
            subtitle: Text('ID: ${restaurante['id']}'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('restaurante_id', restaurante['id']);
              Navigator.pushReplacementNamed(
                context,
                '/dueno_home',
                arguments: restaurante,
              );
            },
          );
        },
      ),
    );
  }
}
