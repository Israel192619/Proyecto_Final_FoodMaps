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
                        Text(
                          'Lista de Bebidas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
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

  void _editarBebida(Map<String, dynamic> bebida) {
    // Implementar lógica de edición
  }
}