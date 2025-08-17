import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../../../config/config.dart';
import 'agregar_producto_page.dart';
import 'editar_producto_page.dart';

String getProductImageUrl(String? imagen) {
  return AppConfig.getImageUrl(imagen);
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
  int? _updatingProductoId;

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

    // Detectar si estamos en escritorio o web
    final isDesktopOrWeb = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    // Obtener el ancho de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;

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
                child: _platos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: isDesktopOrWeb
                        // Vista de cuadrícula para escritorio/web - Ajustado para ser más compacto verticalmente
                        ? GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _calcularColumnCount(screenWidth),
                              // Aspecto ajustado para tarjetas más compactas verticalmente
                              childAspectRatio: 1.05,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _platos.length,
                            itemBuilder: (context, index) => _buildPlatoCard(_platos[index], isDark, isDesktopOrWeb),
                          )
                        // Vista de lista para móvil
                        : ListView.builder(
                            itemCount: _platos.length,
                            itemBuilder: (context, index) => _buildPlatoCard(_platos[index], isDark, isDesktopOrWeb),
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

  // Función para calcular el número de columnas según el ancho de pantalla
  int _calcularColumnCount(double width) {
    if (width > 1200) return 4;      // Pantallas muy grandes (más columnas)
    if (width > 900) return 3;       // Pantallas grandes
    if (width > 600) return 2;       // Pantallas medianas
    return 1;                         // Pantallas pequeñas
  }

  // Widget para construir una tarjeta de plato más compacta
  Widget _buildPlatoCard(Map<String, dynamic> plato, bool isDark, bool isDesktopOrWeb) {
    final imageUrl = getProductImageUrl(plato['imagen']?.toString());
    final disponible = plato['disponible'] == 1;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      color: isDark ? Colors.grey[850] : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
        ),
        child: isDesktopOrWeb
            ? _buildGridCardContent(plato, isDark, imageUrl, disponible)
            : _buildListCardContent(plato, isDark, imageUrl, disponible),
      ),
    );
  }

  // Diseño de tarjeta para vista en grid (escritorio/web) - Más compacto
  Widget _buildGridCardContent(Map<String, dynamic> plato, bool isDark, String imageUrl, bool disponible) {
    return Padding(
      padding: const EdgeInsets.all(6), // Reducido el padding general
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Asegura que la columna ocupe solo el espacio necesario
        children: [
          // Imagen + indicador de disponibilidad
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 80, // Imagen más pequeña
                height: 80, // Imagen más pequeña
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[300]!, width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark ? Colors.grey[700] : Colors.grey[200],
                            child: Icon(Icons.restaurant, size: 35, color: Colors.red.shade400),
                          ),
                        )
                      : Container(
                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                          child: Icon(Icons.restaurant, size: 35, color: Colors.red.shade400),
                        ),
                ),
              ),

              // Indicador de disponibilidad
              InkWell(
                onTap: _updatingProductoId == plato['producto_id']
                    ? null
                    : () => _toggleDisponibilidad(plato),
                child: _updatingProductoId == plato['producto_id']
                    ? Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.all(2),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          disponible ? Icons.check_circle : Icons.cancel,
                          color: disponible ? Colors.green.shade700 : Colors.red.shade700,
                          size: 20, // Icono más pequeño
                        ),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 6), // Espacio reducido

          // Nombre del producto
          Text(
            plato['nombre_producto'] ?? 'Sin nombre',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Precio
          Container(
            margin: const EdgeInsets.symmetric(vertical: 3), // Reducido
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Bs. ${plato['precio'] ?? '0'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Descripción optimizada para ocupar menos espacio vertical
          if (plato['descripcion'] != null && plato['descripcion'].toString().isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 40), // Limitar altura máxima
              margin: const EdgeInsets.only(top: 2, bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                child: Text(
                  plato['descripcion'],
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            const SizedBox(height: 2), // Espacio mínimo cuando no hay descripción

          const Spacer(), // Empuja el botón hacia abajo

          // Botón editar - OPTIMIZADO para ocupar menos espacio
          InkWell(
            onTap: () => _editarPlato(plato),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8), // Reducido
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.edit,
                    size: 11, // Icono más pequeño
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Editar',
                    style: TextStyle(
                      fontSize: 10, // Texto más pequeño
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Diseño de tarjeta para vista en lista (móvil) - Más compacto
  Widget _buildListCardContent(Map<String, dynamic> plato, bool isDark, String imageUrl, bool disponible) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1) Imagen
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        child: Icon(Icons.restaurant, size: 35, color: Colors.red.shade400),
                      ),
                    )
                  : Container(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      child: Icon(Icons.restaurant, size: 35, color: Colors.red.shade400),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // 2) Información central (nombre, precio, descripción)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plato['nombre_producto'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.red.shade700,
                        ),
                      ),
                    ),
                    // Precio
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Bs. ${plato['precio'] ?? '0'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (plato['descripcion'] != null && plato['descripcion'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    plato['descripcion'],
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // 3) Acciones
          Column(
            children: [
              // Indicador disponible
              InkWell(
                onTap: _updatingProductoId == plato['producto_id']
                    ? null
                    : () => _toggleDisponibilidad(plato),
                child: _updatingProductoId == plato['producto_id']
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        disponible ? Icons.check_circle : Icons.cancel,
                        color: disponible ? Colors.green.shade700 : Colors.red.shade700,
                        size: 24,
                      ),
              ),
              const SizedBox(height: 8),
              // Botón editar
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.red, size: 22),
                onPressed: () => _editarPlato(plato),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36),
                tooltip: 'Editar plato',
              ),
            ],
          ),
        ],
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
