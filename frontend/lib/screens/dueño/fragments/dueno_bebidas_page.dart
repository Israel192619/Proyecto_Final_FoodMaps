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
  int? _updatingProductoId;

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

  // NUEVO: Alternar disponibilidad por PUT
  Future<void> _toggleDisponibilidad(Map<String, dynamic> bebida) async {
    if (_menuId == null) return;
    final productoId = bebida['producto_id'];
    setState(() => _updatingProductoId = productoId);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final url = AppConfig.getApiUrl(
      AppConfig.actualizarProductoEndpoint(widget.restauranteId, _menuId!, productoId),
    );
    final disponibleActual = bebida['disponible'] == 1;
    final nuevoDisponible = !disponibleActual;

    final payload = {
      'nombre': (bebida['nombre_producto'] ?? '').toString(),
      'precio': double.tryParse(bebida['precio'].toString()) ?? bebida['precio'],
      'descripcion': (bebida['descripcion'] ?? '').toString(),
      'disponible': nuevoDisponible,
      'tipo': bebida['tipo'] is int ? bebida['tipo'] : int.tryParse('${bebida['tipo']}') ?? 1,
    };

    print('[VISTA][DUENO_BEBIDAS] PUT disponibilidad productoId=$productoId url=$url payload=$payload');

    try {
      final resp = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      print('[VISTA][DUENO_BEBIDAS] Respuesta PUT: ${resp.statusCode} - ${resp.body}');
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        setState(() {
          bebida['disponible'] = nuevoDisponible ? 1 : 0;
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
      print('[VISTA][DUENO_BEBIDAS] Error PUT disponibilidad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth < 500 ? constraints.maxWidth * 0.98 : 420;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _buildContent(context),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
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
                child: _bebidas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            itemCount: _bebidas.length,
                            itemBuilder: (context, index) => _buildBebidaCard(_bebidas[index], isDark, isDesktopOrWeb),
                          )
                        // Vista de lista para móvil
                        : ListView.builder(
                            itemCount: _bebidas.length,
                            itemBuilder: (context, index) => _buildBebidaCard(_bebidas[index], isDark, isDesktopOrWeb),
                          ),
                    ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarBebida,
        icon: const Icon(Icons.add),
        label: const Text('Agregar bebida'),
        backgroundColor: Colors.red,
        heroTag: 'btn_agregar_bebida', // Agregar etiqueta hero única
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

  // Widget para construir una tarjeta de bebida más compacta
  Widget _buildBebidaCard(Map<String, dynamic> bebida, bool isDark, bool isDesktopOrWeb) {
    final imageUrl = getProductImageUrl(bebida['imagen']?.toString());
    final disponible = bebida['disponible'] == 1;

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
            ? _buildGridCardContent(bebida, isDark, imageUrl, disponible)
            : _buildListCardContent(bebida, isDark, imageUrl, disponible),
      ),
    );
  }

  // Diseño de tarjeta para vista en grid (escritorio/web) - Más compacto
  Widget _buildGridCardContent(Map<String, dynamic> bebida, bool isDark, String imageUrl, bool disponible) {
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
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.15 * 255).toInt()), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: isDark ? Colors.grey[700] : Colors.grey[200],
                            child: Icon(Icons.local_drink, size: 35, color: Colors.blue.shade400),
                          ),
                        )
                      : Container(
                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                          child: Icon(Icons.local_drink, size: 35, color: Colors.blue.shade400),
                        ),
                ),
              ),

              // Indicador de disponibilidad
              InkWell(
                onTap: _updatingProductoId == bebida['producto_id']
                    ? null
                    : () => _toggleDisponibilidad(bebida),
                child: _updatingProductoId == bebida['producto_id']
                    ? Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.all(2),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800.withAlpha((0.8 * 255).toInt()) : Colors.white.withAlpha((0.8 * 255).toInt()),
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
            bebida['nombre_producto'] ?? 'Sin nombre',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.blue.shade700,
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
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Bs. ${bebida['precio'] ?? '0'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Descripción optimizada para ocupar menos espacio vertical
          if (bebida['descripcion'] != null && bebida['descripcion'].toString().isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 40), // Limitar altura máxima
              margin: const EdgeInsets.only(top: 2, bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800]!.withAlpha((0.5 * 255).toInt()) : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                child: Text(
                  bebida['descripcion'],
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
            onTap: () => _editarBebida(bebida),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8), // Reducido
              decoration: BoxDecoration(
                color: Colors.red.withAlpha((0.8 * 255).toInt()),
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
  Widget _buildListCardContent(Map<String, dynamic> bebida, bool isDark, String imageUrl, bool disponible) {
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
                  color: Colors.black.withAlpha((0.15 * 255).toInt()),
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
                        child: Icon(Icons.local_drink, size: 35, color: Colors.blue.shade400),
                      ),
                    )
                  : Container(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      child: Icon(Icons.local_drink, size: 35, color: Colors.blue.shade400),
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
                        bebida['nombre_producto'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.blue.shade700,
                        ),
                      ),
                    ),
                    // Precio
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Bs. ${bebida['precio'] ?? '0'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (bebida['descripcion'] != null && bebida['descripcion'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    bebida['descripcion'],
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
                onTap: _updatingProductoId == bebida['producto_id']
                    ? null
                    : () => _toggleDisponibilidad(bebida),
                child: _updatingProductoId == bebida['producto_id']
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
                onPressed: () => _editarBebida(bebida),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36),
                tooltip: 'Editar bebida',
              ),
            ],
          ),
        ],
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