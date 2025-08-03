import 'package:flutter/material.dart';

class BebidasDuenoPage extends StatefulWidget {
  final int restauranteId;

  const BebidasDuenoPage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  _BebidasDuenoPageState createState() => _BebidasDuenoPageState();
}

class _BebidasDuenoPageState extends State<BebidasDuenoPage> {
  List<Map<String, dynamic>> _bebidas = [];

  @override
  void initState() {
    super.initState();
    _fetchBebidas();
  }

  Future<void> _fetchBebidas() async {
    // Simular llamada API para obtener bebidas
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _bebidas = [
        {'id': 1, 'nombre': 'Bebida 1', 'precio': 8.0, 'imagen': ''},
        {'id': 2, 'nombre': 'Bebida 2', 'precio': 10.0, 'imagen': ''},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _bebidas.length,
      itemBuilder: (context, index) {
        final bebida = _bebidas[index];
        return ListTile(
          leading: bebida['imagen'] != null && bebida['imagen'].isNotEmpty
              ? Image.network(bebida['imagen'])
              : Icon(Icons.local_drink),
          title: Text(bebida['nombre']),
          subtitle: Text('\$${bebida['precio'].toString()}'),
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _editarBebida(bebida),
          ),
        );
      },
    );
  }

  void _editarBebida(Map<String, dynamic> bebida) {
    // Implementar lógica de edición
  }
}