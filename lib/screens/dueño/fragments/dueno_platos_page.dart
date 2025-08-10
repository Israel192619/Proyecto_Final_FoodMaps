import 'package:flutter/material.dart';

import 'agregar_producto_page.dart';

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
        {
          'id': 1,
          'nombre': 'Plato 1',
          'precio': 25.0,
          'imagen': '',
          'disponible': true,
          'descripcion': 'Descripción del Plato 1',
        },
        {
          'id': 2,
          'nombre': 'Plato 2',
          'precio': 30.0,
          'imagen': '',
          'disponible': false,
          'descripcion': 'Descripción del Plato 2',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
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
        child: Center(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth * 0.98 : 540;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Card(
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Platos del Restaurante',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.red.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ..._platos.map((plato) {
                            final disponible = plato['disponible'] == true;
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: isDark ? Colors.grey[900] : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: plato['imagen'] != null && plato['imagen'].isNotEmpty
                                          ? Image.network(
                                              plato['imagen'],
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 70,
                                              height: 70,
                                              color: isDark ? Colors.grey[800] : Colors.grey[300],
                                              child: Icon(Icons.food_bank, size: 38, color: Colors.red.shade400),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                plato['nombre'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: isDark ? Colors.white : Colors.red.shade700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                disponible ? Icons.check_circle : Icons.cancel,
                                                color: disponible ? Colors.green : Colors.red,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${plato['precio'].toString()}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                                            ),
                                          ),
                                          if (plato['descripcion'] != null && plato['descripcion'].toString().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6.0),
                                              child: Text(
                                                plato['descripcion'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.red),
                                      onPressed: () => _editarPlato(plato),
                                      tooltip: 'Editar plato',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarPlato,
        icon: Icon(Icons.add),
        label: Text('Agregar plato'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _editarPlato(Map<String, dynamic> plato) {
    // Implementar lógica de edición
  }

  void _agregarPlato() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgregarProductoPage(
          restauranteId: widget.restauranteId,
          tipoProducto: 0, // 0 para plato
        ),
      ),
    );
  }
}
