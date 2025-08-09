import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BebidasRest extends StatelessWidget {
  final int restaurantId;
  const BebidasRest({super.key, required this.restaurantId});

  Future<List<dynamic>> fetchBebidas() async {
    final response = await http.get(
      Uri.parse('http://192.168.100.5/api/bebidas?restaurante_id=$restaurantId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar bebidas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: fetchBebidas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bebidas = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: bebidas.length,
          itemBuilder: (context, index) {
            final bebida = bebidas[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Image.network(
                  bebida['imagen'],
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.local_drink, size: 40),
                ),
                title: Text(bebida['nombre']),
                subtitle: Text('Bs ${bebida['precio']}'),
              ),
            );
          },
        );
      },
    );
  }
}
