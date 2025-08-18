// maps_page.dart

import 'dart:async';
import 'dart:convert'; // <-- Agrega este import
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_custom_windows/google_map_custom_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:url_launcher/url_launcher.dart'; // Añade este import
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../config/theme_provider.dart';
import '../../../config/config.dart';
import 'package:foodmaps/constants/restaurant_info_window.dart';
import '../../publica/Menu_Restaurante.dart'; // Agrega este import

class MapsPage extends StatefulWidget {
  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  GoogleMapController? _mapController;
  final GoogleMapCustomWindowController _customController = GoogleMapCustomWindowController();
  final Set<Marker> _markers = {};
  List<LatLng> infoPositions = [];
  List<Widget> infoWidgets = [];
  List<Map<String, dynamic>> _restaurantesData = [];
  int _estadoFiltro = -1; // -1: todos, 0: cerrado, 1: abierto

  static final LatLng _defaultCenter = LatLng(-17.382202, -66.151789);

  // Guarda el último modo de tema para detectar cambios
  bool? _lastIsDark;
  bool _mapStyleApplied = false;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isDesktop) {
      print('[MAPS_PAGE] initState: escritorio detectado, solo fetch de restaurantes');
      _fetchLocationsFromApi();
    } else {
      _checkPermissionAndFetch();
    }
    _connectWebSocketChannel();
  }

  void _connectWebSocketChannel() {
    if (_channel != null) {
      print('[WSO][CLIENTE] Cerrando canal WebSocket anterior antes de reconectar');
      _channel?.sink.close();
      _channel = null;
    }
    final wsUrl = AppConfig.getWebSocketUrl();
    print('[WSO][CLIENTE] WebSocket: $wsUrl');
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    final subscribeMsg = {
      "event": "pusher:subscribe",
      "data": {"channel": "restaurantes"}
    };
    print('[WSO][CLIENTE] Enviando mensaje de suscripción: $subscribeMsg');
    _channel?.sink.add(jsonEncode(subscribeMsg));
    _channel?.stream.listen(
      (message) {
        print('[WSO][CLIENTE] Mensaje recibido del WebSocket: $message');
        try {
          final data = jsonDecode(message);
          if (data is Map && data.containsKey('event')) {
            if (data['event'] == 'status.updated') {
              print('[WSO][CLIENTE] Evento status.updated recibido: ${data['data']}');
              _handleRestaurantStatusUpdate(data['data']);
            } else if (data['event'] == 'pusher:ping') {
              print('[WSO][CLIENTE] Recibido pusher:ping, enviando pusher:pong');
              _channel?.sink.add(jsonEncode({'event': 'pusher:pong', 'data': {}}));
            }
          }
        } catch (e) {
          print('[WSO][CLIENTE] Error al procesar mensaje WebSocket: $e');
        }
      },
      onError: (error) {
        print('[WSO][CLIENTE] Error en la conexión WebSocket: $error');
      },
      onDone: () {
        print('[WSO][CLIENTE] Conexión WebSocket cerrada');
      },
    );
  }

  void _handleRestaurantStatusUpdate(dynamic eventData) {
    Map<String, dynamic>? parsed;
    if (eventData is String) {
      try {
        parsed = jsonDecode(eventData);
      } catch (e) {
        print('[WSO][CLIENTE] Error al decodificar eventData: $e');
        return;
      }
    } else if (eventData is Map<String, dynamic>) {
      parsed = eventData;
    }
    if (parsed != null && parsed.containsKey('id') && parsed.containsKey('estado')) {
      final id = parsed['id'];
      final estado = parsed['estado'];
      print('[WSO][CLIENTE] Actualizando marcador para restaurante_id=$id, estado=$estado');
      actualizarMarcadorRestaurantePorId(id, estado);
    } else {
      print('[WSO][CLIENTE] eventData no contiene los campos necesarios: $parsed');
    }
  }

  void actualizarMarcadorRestaurantePorId(dynamic id, dynamic nuevoEstado) {
    print('[WSO][CLIENTE] actualizarMarcadorRestaurantePorId llamado para id=$id, estado=$nuevoEstado');
    Marker? marcadorAnterior;
    try {
      marcadorAnterior = _markers.firstWhere(
        (m) => m.markerId.value == id.toString(),
      );
    } catch (e) {
      marcadorAnterior = null;
    }
    setState(() {
      if (marcadorAnterior != null) {
        print('[WSO][CLIENTE] Eliminando marcador anterior de id=$id');
        _markers.remove(marcadorAnterior);
        final nuevaPos = marcadorAnterior.position;
        final nuevoIcono = nuevoEstado == 1
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        Map<String, dynamic>? restauranteData;
        try {
          restauranteData = _restaurantesData.firstWhere(
            (rest) => rest['id'].toString() == id.toString(),
          );
        } catch (e) {
          print('[WSO][CLIENTE] No se encontraron datos para el restaurante id=$id');
        }
        final nuevoMarcador = Marker(
          markerId: MarkerId(id.toString()),
          position: nuevaPos,
          icon: nuevoIcono,
          onTap: () {
            if (restauranteData != null) {
              final imagenSafe = getRestauranteImageUrl(restauranteData['imagen']?.toString());
              final infoWidget = RestaurantInfoWindow(
                restaurantData: {
                  ...restauranteData,
                  'imagen': imagenSafe,
                  'estado': nuevoEstado,
                },
                onMenuPressed: () {
                  _customController.hideInfoWindow!();
                  final int restaurantId = restauranteData?['restaurante_id'] is int
                      ? restauranteData!['restaurante_id']
                      : (restauranteData?['id'] is int
                          ? restauranteData!['id']
                          : int.tryParse(restauranteData?['restaurante_id']?.toString() ?? restauranteData?['id']?.toString() ?? '0') ?? 0);
                  final String name = restauranteData?['nom_rest'] ?? restauranteData?['nombre_restaurante'] ?? '';
                  final String phone = restauranteData?['celular']?.toString() ?? '';
                  final String imageUrl = restauranteData?['imagen']?.toString() ?? '';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuRestaurante(
                        restaurantId: restaurantId,
                        name: name,
                        phone: phone,
                        imageUrl: imageUrl,
                      ),
                    ),
                  );
                },
              );
              _customController.addInfoWindow!([infoWidget], [nuevaPos]);
            }
          },
        );
        _markers.add(nuevoMarcador);
        print('[WSO][CLIENTE] Marcador actualizado en _markers para id=$id');
      } else {
        print('[WSO][CLIENTE] No se encontró marcador para id=$id');
      }
    });
  }

  Future<void> _applyMapStyle(bool isDark) async {
    if (_mapController == null) {
      print('[MAP_STYLE] _mapController es null, no se puede aplicar el estilo');
      return;
    }
    final stylePath = isDark
        ? 'assets/map_styles/map_style_no_labels_night.json'
        : 'assets/map_styles/map_style_no_labels.json';
    print('[MAP_STYLE] Cargando estilo: $stylePath');
    try {
      final style = await rootBundle.loadString(stylePath);
      await _mapController?.setMapStyle(style);
      print('[MAP_STYLE] Estilo aplicado correctamente');
      _mapStyleApplied = true;
    } catch (e) {
      print('[MAP_STYLE] Error loading map style: $e');
    }
  }

  Future<void> _checkPermissionAndFetch() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        final status = await Permission.location.status;
        if (status.isGranted && await Geolocator.isLocationServiceEnabled()) {
          position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        }
      }

      if (position != null) {
        _animateTo(position.latitude, position.longitude, 17);
      } else {
        _animateTo(_defaultCenter.latitude, _defaultCenter.longitude, 15);
      }
    } catch (e) {
      print('Error de ubicación: $e');
      _animateTo(_defaultCenter.latitude, _defaultCenter.longitude, 15);
    }

    await _fetchLocationsFromApi();
  }

  @override
  Widget build(BuildContext context) {
    // Detectar escritorio
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    print('[MAPS_PAGE] Plataforma detectada: ${defaultTargetPlatform.toString()}, isDesktop=$isDesktop, kIsWeb=$kIsWeb');
    print('[MAPS_PAGE] _restaurantesData.length=${_restaurantesData.length}');

    if (isDesktop) {
      print('[MAPS_PAGE] Mostrando tabla de restaurantes en escritorio');
      return _buildDesktopTable(context);
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Aplica el estilo si el controlador ya existe y el tema cambió o nunca se aplicó
        if (_mapController != null &&
            (_lastIsDark != themeProvider.isDarkMode || !_mapStyleApplied)) {
          print('[MAP_STYLE] build() detecta cambio de tema o estilo no aplicado');
          _applyMapStyle(themeProvider.isDarkMode);
        }
        _lastIsDark = themeProvider.isDarkMode;

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 10,
                          children: [
                            ChoiceChip(
                              label: Row(
                                children: const [
                                  Icon(Icons.all_inclusive, size: 18),
                                  SizedBox(width: 6),
                                  Text('Todos'),
                                ],
                              ),
                              selected: _estadoFiltro == -1,
                              selectedColor: Colors.red.shade400,
                              backgroundColor: Colors.red.shade100,
                              labelStyle: TextStyle(
                                color: _estadoFiltro == -1 ? Colors.white : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              elevation: _estadoFiltro == -1 ? 6 : 2,
                              onSelected: (selected) {
                                setState(() {
                                  _estadoFiltro = -1;
                                  _actualizarMarcadores();
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  SizedBox(width: 6),
                                  Text('Abiertos'),
                                ],
                              ),
                              selected: _estadoFiltro == 1,
                              selectedColor: Colors.green.shade400,
                              backgroundColor: Colors.green.shade100,
                              labelStyle: TextStyle(
                                color: _estadoFiltro == 1 ? Colors.white : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              elevation: _estadoFiltro == 1 ? 6 : 2,
                              onSelected: (selected) {
                                setState(() {
                                  _estadoFiltro = 1;
                                  _actualizarMarcadores();
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Row(
                                children: const [
                                  Icon(Icons.cancel, color: Colors.red, size: 18),
                                  SizedBox(width: 6),
                                  Text('Cerrados'),
                                ],
                              ),
                              selected: _estadoFiltro == 0,
                              selectedColor: Colors.red.shade400,
                              backgroundColor: Colors.red.shade100,
                              labelStyle: TextStyle(
                                color: _estadoFiltro == 0 ? Colors.white : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              elevation: _estadoFiltro == 0 ? 6 : 2,
                              onSelected: (selected) {
                                setState(() {
                                  _estadoFiltro = 0;
                                  _actualizarMarcadores();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) async {
                        print('[MAP_STYLE] onMapCreated llamado');
                        _mapController = controller;
                        _mapStyleApplied = false;
                        await _applyMapStyle(themeProvider.isDarkMode);
                        _customController.googleMapController = controller;
                      },
                      initialCameraPosition: CameraPosition(target: _defaultCenter, zoom: 15),
                      markers: _markers,
                      myLocationEnabled: true,
                      onTap: (_) => _customController.hideInfoWindow!(),
                      onCameraMove: (_) => _customController.onCameraMove!(),
                    ),
                    CustomMapInfoWindow(
                      controller: _customController,
                      offset: Offset(0, 30),
                      height: 170,
                      width: 180,
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchLocationsFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('[MAPS_PAGE] _fetchLocationsFromApi llamado. token=$token');
    if (token == null) {
      print('[MAPS_PAGE] No hay token de autenticación');
      return;
    }
    try {
      final url = '${AppConfig.apiBaseUrl}/clientes/restaurantes';
      print('[MAPS_PAGE] Realizando GET a $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[MAPS_PAGE] Respuesta statusCode: ${response.statusCode}');
      print('[MAPS_PAGE] Respuesta body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List restaurantes = data is Map && data.containsKey('data') ? data['data'] : [];
        print('[MAPS_PAGE] Restaurantes extraídos: $restaurantes');
        _restaurantesData = [];
        for (var obj in restaurantes) {
          _restaurantesData.add(obj);
        }
        _actualizarMarcadores();
      } else {
        print('[MAPS_PAGE] Error al obtener restaurantes: ${response.statusCode}');
      }
    } catch (e) {
      print('[MAPS_PAGE] Excepción al obtener restaurantes: $e');
    }
  }

  void _actualizarMarcadores() {
    // Oculta cualquier ventana abierta antes de actualizar marcadores
    _customController.hideInfoWindow!();

    _markers.clear();
    for (var obj in _restaurantesData) {
      final marker = MapsUtils.createMarker(
        obj: obj,
        estadoFiltro: _estadoFiltro,
        onMenuPressed: _openDetail,
        context: context,
        customController: _customController,
      );
      if (marker != null) _markers.add(marker);
    }
    setState(() {});
  }

  void _openDetail(Map obj) {
    // Oculta el info window antes de navegar
    _customController.hideInfoWindow!();

    // Corrige los campos para evitar errores de tipo
    final int restaurantId = obj['restaurante_id'] is int
        ? obj['restaurante_id']
        : (obj['id'] is int
        ? obj['id']
        : int.tryParse(obj['restaurante_id']?.toString() ?? obj['id']?.toString() ?? '0') ?? 0);
    final String name = obj['nom_rest'] ?? obj['nombre_restaurante'] ?? '';
    final String phone = obj['celular']?.toString() ?? '';
    final String imageUrl = getRestauranteImageUrl(obj['imagen']?.toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuRestaurante(
          restaurantId: restaurantId,
          name: name,
          phone: phone,
          imageUrl: imageUrl,
        ),
      ),
    );
  }

  Future<void> _animateTo(double lat, double lng, double zoom) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(lat, lng), zoom: zoom)),
      );
    }
  }

  Widget _buildDesktopTable(BuildContext context) {
    // Añade filtro de estado arriba de la tabla
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
        centerTitle: true,
        backgroundColor: isDark ? Colors.black : Colors.red.shade700,
        elevation: 2,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      spacing: 10,
                      children: [
                        ChoiceChip(
                          label: Row(
                            children: const [
                              Icon(Icons.all_inclusive, size: 18),
                              SizedBox(width: 6),
                              Text('Todos'),
                            ],
                          ),
                          selected: _estadoFiltro == -1,
                          selectedColor: Colors.red.shade400,
                          backgroundColor: Colors.red.shade100,
                          labelStyle: TextStyle(
                            color: _estadoFiltro == -1 ? Colors.white : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: _estadoFiltro == -1 ? 6 : 2,
                          onSelected: (selected) {
                            setState(() {
                              _estadoFiltro = -1;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              SizedBox(width: 6),
                              Text('Abiertos'),
                            ],
                          ),
                          selected: _estadoFiltro == 1,
                          selectedColor: Colors.green.shade400,
                          backgroundColor: Colors.green.shade100,
                          labelStyle: TextStyle(
                            color: _estadoFiltro == 1 ? Colors.white : Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: _estadoFiltro == 1 ? 6 : 2,
                          onSelected: (selected) {
                            setState(() {
                              _estadoFiltro = 1;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: Row(
                            children: const [
                              Icon(Icons.cancel, color: Colors.red, size: 18),
                              SizedBox(width: 6),
                              Text('Cerrados'),
                            ],
                          ),
                          selected: _estadoFiltro == 0,
                          selectedColor: Colors.red.shade400,
                          backgroundColor: Colors.red.shade100,
                          labelStyle: TextStyle(
                            color: _estadoFiltro == 0 ? Colors.white : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: _estadoFiltro == 0 ? 6 : 2,
                          onSelected: (selected) {
                            setState(() {
                              _estadoFiltro = 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: MapsDesktopTable(
              restaurantesData: _restaurantesData.where((rest) {
                final estado = rest['estado'] is int
                    ? rest['estado']
                    : int.tryParse(rest['estado'].toString()) ?? 1;
                if (_estadoFiltro == -1) return true;
                return estado == _estadoFiltro;
              }).toList(),
              onMenuPressed: _openDetail,
              showEstado: true, // Nuevo parámetro para mostrar columna de estado
            ),
          ),
        ],
      ),
    );
  }
}

class MapsDesktopTable extends StatelessWidget {
  final List<Map<String, dynamic>> restaurantesData;
  final void Function(Map<String, dynamic>)? onMenuPressed;
  final bool showEstado;

  const MapsDesktopTable({
    Key? key,
    required this.restaurantesData,
    this.onMenuPressed,
    this.showEstado = false,
  }) : super(key: key);

  void _abrirGoogleMaps(BuildContext context, String ubicacion) async {
    if (ubicacion.contains(',')) {
      final parts = ubicacion.split(',');
      final lat = parts[0].trim();
      final lng = parts[1].trim();
      final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    // Calcula el número de columnas dinámicamente
    final int columnCount = 4 + (showEstado ? 1 : 0);
    // Ajusta el ancho mínimo por columna (ejemplo: 180px por columna)
    final double minTableWidth = columnCount * 180.0;
    final double cardWidth = screenWidth < minTableWidth + 40
        ? minTableWidth + 40
        : (screenWidth < 1200 ? screenWidth * 0.95 : 1100);
    final double cardHeight = screenHeight < 700 ? screenHeight * 0.8 : 500;
    final double bottomNavHeight = kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom + 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
        centerTitle: true,
        backgroundColor: isDark ? Colors.black : Colors.red.shade700,
        elevation: 2,
      ),
      body: restaurantesData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.only(bottom: bottomNavHeight), // Ajusta el padding inferior dinámicamente
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: minTableWidth,
                    maxWidth: cardWidth,
                  ),
                  child: DataTable(
                    columnSpacing: 32,
                    headingRowColor: MaterialStateProperty.all(
                      isDark ? Colors.red.shade900 : Colors.red.shade100,
                    ),
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 90,
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.red.withOpacity(0.08);
                        }
                        return isDark
                            ? Colors.grey[850]
                            : Colors.white;
                      },
                    ),
                    columns: [
                      const DataColumn(label: Text('Logo', style: TextStyle(fontWeight: FontWeight.bold))),
                      const DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                      const DataColumn(label: Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold))),
                      if (showEstado)
                        const DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                      const DataColumn(label: Text('Ver Menú', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: restaurantesData.map((rest) {
                      final imageUrl = getRestauranteImageUrl(rest['imagen']?.toString());
                      final nombre = rest['nombre_restaurante'] ?? '';
                      final ubicacion = rest['ubicacion'] ?? '';
                      final estado = rest['estado'] is int
                          ? rest['estado']
                          : int.tryParse(rest['estado'].toString()) ?? 1;
                      return DataRow(
                        cells: [
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                                    : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 32, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                nombre,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.red.shade700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.location_on, color: Colors.red, size: 18),
                                label: const Text('Ver en Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade700,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: ubicacion.toString().contains(',')
                                    ? () => _abrirGoogleMaps(context, ubicacion)
                                    : null,
                              ),
                            ),
                          ),
                          if (showEstado)
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      estado == 1 ? Icons.check_circle : Icons.cancel,
                                      color: estado == 1 ? Colors.green : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      estado == 1 ? 'Abierto' : 'Cerrado',
                                      style: TextStyle(
                                        color: estado == 1 ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ElevatedButton.icon(
                                onPressed: onMenuPressed != null
                                    ? () => onMenuPressed!(rest)
                                    : null,
                                icon: const Icon(Icons.restaurant_menu, size: 18),
                                label: const Text('Ver Menú'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String getRestauranteImageUrl(String? imagen) {
  return AppConfig.getImageUrl(imagen);
}

class MapsUtils {
  static LatLng? decodeLatLng(String? ubicacion) {
    if (ubicacion != null && ubicacion.contains(',')) {
      final parts = ubicacion.split(',');
      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return null;
  }

  static Marker? createMarker({
    required Map<String, dynamic> obj,
    required int estadoFiltro,
    required Function(Map<String, dynamic>) onMenuPressed,
    required BuildContext context,
    required GoogleMapCustomWindowController customController,
  }) {
    final estado = obj['estado'] is int ? obj['estado'] : int.tryParse(obj['estado'].toString()) ?? 1;
    if (estadoFiltro != -1 && estado != estadoFiltro) return null;

    final latLng = decodeLatLng(obj['ubicacion']?.toString());
    if (latLng == null) return null;

    final markerId = MarkerId(obj['id'].toString());
    final icon = estado == 1
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
        : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    return Marker(
      markerId: markerId,
      position: latLng,
      icon: icon,
      onTap: () {
        final infoWidget = RestaurantInfoWindow(
          restaurantData: {
            ...obj,
            'imagen': getRestauranteImageUrl(obj['imagen']?.toString()),
          },
          onMenuPressed: () => onMenuPressed(obj),
        );
        customController.addInfoWindow!([infoWidget], [latLng]);
      },
    );
  }
}
