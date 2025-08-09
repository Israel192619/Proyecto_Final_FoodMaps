import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlatosRest extends StatelessWidget {
  final int restaurantId;
  const PlatosRest({super.key, required this.restaurantId});

  Future<List<dynamic>> fetchPlatos() async {
    final response = await http.get(
      Uri.parse('http://192.168.100.5/api/platos?restaurante_id=$restaurantId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); // Asegúrate que el JSON sea una lista
    } else {
      throw Exception('Error al cargar platos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: fetchPlatos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final platos = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: platos.length,
          itemBuilder: (context, index) {
            final plato = platos[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Image.network(
                  plato['imagen'],
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.fastfood, size: 40),
                ),
                title: Text(plato['nombre']),
                subtitle: Text('Bs ${plato['precio']}'),
              ),
            );
          },
        );
      },
    );
  }
}
