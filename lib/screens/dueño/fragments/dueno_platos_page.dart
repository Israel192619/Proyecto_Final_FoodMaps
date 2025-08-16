import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/config.dart';
import 'agregar_producto_page.dart';

String getProductImageUrl(String? imagen) {
  if (imagen == null || imagen.isEmpty) return '';
  if (imagen.startsWith('http')) return imagen;
  return '${AppConfig.storageBaseUrl}$imagen';
}

class PlatosDuenoPage extends StatefulWidget {
  final int restauranteId;

  const PlatosDuenoPage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  _PlatosDuenoPageState createState() => _PlatosDuenoPageState();
}

class _PlatosDuenoPageState extends State<PlatosDuenoPage> {
  List<dynamic> _platos = [];
  bool _loading = true;
  int? _menuId;

  @override
  void initState() {
    super.initState();
    print('[VISTA][DUENO_PLATOS] Iniciando con restauranteId: ${widget.restauranteId}');
    _fetchRestauranteDetalle();
  }

  Future<void> _fetchRestauranteDetalle() async {
    setState(() {
      _loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = AppConfig.getApiUrl(AppConfig.restauranteClienteDetalleEndpoint(widget.restauranteId));
    print('[VISTA][DUENO_PLATOS] URL detalle restaurante: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[VISTA][DUENO_PLATOS] Respuesta detalle restaurante statusCode: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rest = data['data'];
        print('[VISTA][DUENO_PLATOS] Detalle restaurante recibido: $rest');
        setState(() {
          _menuId = rest['menu_id'];
          print('[VISTA][DUENO_PLATOS] menu_id: $_menuId');
        });
        if (_menuId != null) {
          await _fetchProductos();
        }
      }
    } catch (e) {
      print('[VISTA][DUENO_PLATOS] Error al obtener detalle restaurante: $e');
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchProductos() async {
    if (_menuId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = AppConfig.getApiUrl(
      AppConfig.productosMenuRestauranteEndpoint(widget.restauranteId, _menuId!),
    );
    print('[VISTA][DUENO_PLATOS] URL productos: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[VISTA][DUENO_PLATOS] Respuesta productos statusCode: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[VISTA][DUENO_PLATOS] Productos recibidos: ${data['data']}');
        final productos = data['data'] ?? [];
        // Filtrar solo platos (tipo == 0)
        final platos = productos.where((p) => p['tipo'] == 0).toList();
        print('[VISTA][DUENO_PLATOS] Platos filtrados: ${platos.length}');
        setState(() {
          _platos = platos;
        });
      }
    } catch (e) {
      print('[VISTA][DUENO_PLATOS] Error al obtener productos: $e');
    }
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
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
                                if (_platos.isEmpty)
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay platos registrados',
                                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ..._platos.map((plato) {
                                    final imageUrl = getProductImageUrl(plato['imagen']?.toString());
                                    final disponible = plato['disponible'] == 1;
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
                                                            child: Icon(Icons.food_bank, size: 38, color: Colors.red.shade400),
                                                          ),
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
                                                      Expanded(
                                                        child: Text(
                                                          plato['nombre_producto'] ?? 'Sin nombre',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 18,
                                                            color: isDark ? Colors.white : Colors.red.shade700,
                                                          ),
                                                        ),
                                                      ),
                                                      Icon(
                                                        disponible ? Icons.check_circle : Icons.cancel,
                                                        color: disponible ? Colors.green : Colors.red,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Bs. ${plato['precio'] ?? '0'}',
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
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
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
    print('[VISTA][DUENO_PLATOS] Editar plato: ${plato['nombre_producto']}');
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
    ).then((_) {
      // Refrescar la lista cuando regrese de agregar producto
      _fetchRestauranteDetalle();
    });
  }
}
