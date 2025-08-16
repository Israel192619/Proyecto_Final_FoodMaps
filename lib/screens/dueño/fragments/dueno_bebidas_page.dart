import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/config.dart';
import 'agregar_producto_page.dart';
import 'editar_producto_page.dart'; // Agrega este import

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
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Card(
                              elevation: 12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              color: isDark ? Colors.grey[850] : Colors.white,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: isDark
                                      ? LinearGradient(
                                          colors: [Colors.grey[800]!, Colors.grey[850]!],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : LinearGradient(
                                          colors: [Colors.white, Colors.red.shade50],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 1) Imagen + Precio debajo
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.15),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(14),
                                              child: SizedBox(
                                                width: 100,
                                                height: 100,
                                                child: imageUrl.isNotEmpty
                                                    ? Image.network(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) => Container(
                                                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                                                          child: Icon(Icons.local_drink, size: 50, color: Colors.blue.shade400),
                                                        ),
                                                      )
                                                    : Container(
                                                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                                                        child: Icon(Icons.local_drink, size: 50, color: Colors.blue.shade400),
                                                      ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Precio debajo de la imagen (azul)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.blue.shade400, Colors.blue.shade600],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.blue.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              'Bs. ${bebida['precio'] ?? '0'}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),

                                      // 2) Nombre y descripción
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              bebida['nombre_producto'] ?? 'Sin nombre',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: isDark ? Colors.white : Colors.blue.shade700,
                                              ),
                                            ),
                                            if (bebida['descripcion'] != null && bebida['descripcion'].toString().isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                bebida['descripcion'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                                                  height: 1.3,
                                                ),
                                                // Se elimina el truncado para mostrar todo el texto
                                                // maxLines: 3,
                                                // overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // 3) Indicador de disponibilidad (icono grande) + botón editar
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Icon(
                                            disponible ? Icons.check_circle : Icons.cancel,
                                            color: disponible ? Colors.green.shade700 : Colors.red.shade700,
                                            size: 28, // ligeramente más grande
                                          ),
                                          const SizedBox(height: 12),
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.red),
                                            onPressed: () => _editarBebida(bebida),
                                            tooltip: 'Editar bebida',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarBebida,
        icon: const Icon(Icons.add),
        label: const Text('Agregar bebida'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _editarBebida(Map<String, dynamic> bebida) {
    print('[VISTA][DUENO_BEBIDAS] Editar bebida: ${bebida['nombre_producto']}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarProductoPage(
          producto: bebida,
          restauranteId: widget.restauranteId,
          menuId: _menuId!,
        ),
      ),
    ).then((result) {
      // Si se guardaron cambios, refresca la lista
      if (result == true) {
        _fetchRestauranteDetalle();
      }
    });
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