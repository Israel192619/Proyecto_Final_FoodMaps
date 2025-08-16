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
  int? _updatingProductoId; // <-- NUEVO: id del producto en actualización

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

  // NUEVO: Alternar disponibilidad y actualizar por PUT
  Future<void> _toggleDisponibilidad(Map<String, dynamic> plato) async {
    if (_menuId == null) return;
    final productoId = plato['producto_id'];
    setState(() => _updatingProductoId = productoId);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = AppConfig.getApiUrl(
      AppConfig.actualizarProductoEndpoint(widget.restauranteId, _menuId!, productoId),
    );
    final disponibleActual = plato['disponible'] == 1;
    final nuevoDisponible = !disponibleActual;

    // Payload completo (backend requiere nombre y precio)
    final payload = {
      'nombre': (plato['nombre_producto'] ?? '').toString(),
      'precio': double.tryParse(plato['precio'].toString()) ?? plato['precio'],
      'descripcion': (plato['descripcion'] ?? '').toString(),
      'disponible': nuevoDisponible, // booleano en JSON
      'tipo': plato['tipo'] is int ? plato['tipo'] : int.tryParse('${plato['tipo']}') ?? 0,
    };

    print('[VISTA][DUENO_PLATOS] PUT disponibilidad productoId=$productoId url=$url payload=$payload');

    try {
      final resp = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      print('[VISTA][DUENO_PLATOS] Respuesta PUT: ${resp.statusCode} - ${resp.body}');
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        setState(() {
          plato['disponible'] = nuevoDisponible ? 1 : 0; // Actualiza localmente
          _updatingProductoId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disponibilidad actualizada (${nuevoDisponible ? 'Disponible' : 'No disponible'})')),
        );
      } else {
        setState(() => _updatingProductoId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: ${resp.body}')),
        );
      }
    } catch (e) {
      setState(() => _updatingProductoId = null);
      print('[VISTA][DUENO_PLATOS] Error PUT disponibilidad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')),
      );
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
                                                          child: Icon(Icons.food_bank, size: 50, color: Colors.red.shade400),
                                                        ),
                                                      )
                                                    : Container(
                                                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                                                        child: Icon(Icons.food_bank, size: 50, color: Colors.red.shade400),
                                                      ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Precio debajo de la imagen
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.red.shade400, Colors.red.shade600],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.red.withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              'Bs. ${plato['precio'] ?? '0'}',
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
                                              plato['nombre_producto'] ?? 'Sin nombre',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: isDark ? Colors.white : Colors.red.shade700,
                                              ),
                                            ),
                                            if (plato['descripcion'] != null && plato['descripcion'].toString().isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                plato['descripcion'],
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
                                          // Icono clickeable con loader mientras actualiza
                                          InkWell(
                                            onTap: _updatingProductoId == plato['producto_id']
                                                ? null
                                                : () => _toggleDisponibilidad(plato),
                                            borderRadius: BorderRadius.circular(20),
                                            child: _updatingProductoId == plato['producto_id']
                                                ? const SizedBox(
                                                    width: 28,
                                                    height: 28,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : Icon(
                                                    disponible ? Icons.check_circle : Icons.cancel,
                                                    color: disponible ? Colors.green.shade700 : Colors.red.shade700,
                                                    size: 28,
                                                  ),
                                          ),
                                          const SizedBox(height: 12),
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.red),
                                            onPressed: () => _editarPlato(plato),
                                            tooltip: 'Editar plato',
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
        onPressed: _agregarPlato,
        icon: const Icon(Icons.add),
        label: const Text('Agregar plato'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _editarPlato(Map<String, dynamic> plato) {
    print('[VISTA][DUENO_PLATOS] Editar plato: ${plato['nombre_producto']}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarProductoPage(
          producto: plato,
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
