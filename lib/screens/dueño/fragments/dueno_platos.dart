import 'package:flutter/material.dart';

class PlatosDuenoPage extends StatefulWidget {
  final int restauranteId;

  const PlatosDuenoPage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  _PlatosDuenoPageState createState() => _PlatosDuenoPageState();
}

class _PlatosDuenoPageState extends State<PlatosDuenoPage> {
  List<Map<String, dynamic>> _platos = [];

  @override
  void initState() {
    super.initState();
    _fetchPlatos();
  }

  Future<void> _fetchPlatos() async {
    // Simular llamada API para obtener platos
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _platos = [
        {'id': 1, 'nombre': 'Plato 1', 'precio': 25.0, 'imagen': ''},
        {'id': 2, 'nombre': 'Plato 2', 'precio': 30.0, 'imagen': ''},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _platos.length,
      itemBuilder: (context, index) {
        final plato = _platos[index];
        return ListTile(
          leading: plato['imagen'] != null && plato['imagen'].isNotEmpty
              ? Image.network(plato['imagen'])
              : Icon(Icons.food_bank),
          title: Text(plato['nombre']),
          subtitle: Text('\$${plato['precio'].toString()}'),
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editarPlato(plato),
          ),
        );
      },
    );
  }

  void _editarPlato(Map<String, dynamic> plato) {
    // Implementar lógica de edición
  }
}