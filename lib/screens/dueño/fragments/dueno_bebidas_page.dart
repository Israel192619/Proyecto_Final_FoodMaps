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

class BebidasDuenoPage extends StatefulWidget {
  final int restauranteId;

  const BebidasDuenoPage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  _BebidasDuenoPageState createState() => _BebidasDuenoPageState();
}

class _BebidasDuenoPageState extends State<BebidasDuenoPage> {
  List<dynamic> _bebidas = [];
  bool _loading = true;
  int? _menuId;

  @override
  void initState() {
    super.initState();
    print('[VISTA][DUENO_BEBIDAS] Iniciando con restauranteId: ${widget.restauranteId}');
    _fetchRestauranteDetalle();
  }

  Future<void> _fetchRestauranteDetalle() async {
    setState(() {
      _loading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = AppConfig.getApiUrl(AppConfig.restauranteClienteDetalleEndpoint(widget.restauranteId));
    print('[VISTA][DUENO_BEBIDAS] URL detalle restaurante: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[VISTA][DUENO_BEBIDAS] Respuesta detalle restaurante statusCode: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rest = data['data'];
        print('[VISTA][DUENO_BEBIDAS] Detalle restaurante recibido: $rest');
        setState(() {
          _menuId = rest['menu_id'];
          print('[VISTA][DUENO_BEBIDAS] menu_id: $_menuId');
        });
        if (_menuId != null) {
          await _fetchProductos();
        }
      }
    } catch (e) {
      print('[VISTA][DUENO_BEBIDAS] Error al obtener detalle restaurante: $e');
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
    print('[VISTA][DUENO_BEBIDAS] URL productos: $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[VISTA][DUENO_BEBIDAS] Respuesta productos statusCode: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[VISTA][DUENO_BEBIDAS] Productos recibidos: ${data['data']}');
        final productos = data['data'] ?? [];
        // Filtrar solo bebidas (tipo == 1)
        final bebidas = productos.where((p) => p['tipo'] == 1).toList();
        print('[VISTA][DUENO_BEBIDAS] Bebidas filtradas: ${bebidas.length}');
        setState(() {
          _bebidas = bebidas;
        });
      }
    } catch (e) {
      print('[VISTA][DUENO_BEBIDAS] Error al obtener productos: $e');
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
                                  'Lista de Bebidas',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.red.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                if (_bebidas.isEmpty)
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.local_drink, size: 80, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay bebidas registradas',
                                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ..._bebidas.map((bebida) {
                                    final imageUrl = getProductImageUrl(bebida['imagen']?.toString());
                                    final disponible = bebida['disponible'] == 1;
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
                                                            child: Icon(Icons.local_drink, size: 38, color: Colors.blue.shade400),
                                                          ),
                                                    )
                                                  : Container(
                                                      width: 70,
                                                      height: 70,
                                                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                                                      child: Icon(Icons.local_drink, size: 38, color: Colors.blue.shade400),
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
                                                          bebida['nombre_producto'] ?? 'Sin nombre',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 18,
                                                            color: isDark ? Colors.white : Colors.blue.shade700,
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
                                                    'Bs. ${bebida['precio'] ?? '0'}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                                                    ),
                                                  ),
                                                  if (bebida['descripcion'] != null && bebida['descripcion'].toString().isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 6.0),
                                                      child: Text(
                                                        bebida['descripcion'],
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
                                              onPressed: () => _editarBebida(bebida),
                                              tooltip: 'Editar bebida',
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
        onPressed: _agregarBebida,
        icon: Icon(Icons.add),
        label: Text('Agregar bebida'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _editarBebida(Map<String, dynamic> bebida) {
    // Implementar lógica de edición
    print('[VISTA][DUENO_BEBIDAS] Editar bebida: ${bebida['nombre_producto']}');
  }

  void _agregarBebida() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgregarProductoPage(
          restauranteId: widget.restauranteId,
          tipoProducto: 1, // 1 para bebida
        ),
      ),
    ).then((_) {
      // Refrescar la lista cuando regrese de agregar producto
      _fetchRestauranteDetalle();
    });
  }
}