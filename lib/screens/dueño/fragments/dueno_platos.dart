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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
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
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _editarPlato(Map<String, dynamic> plato) {
    // Implementar lógica de edición
  }
}