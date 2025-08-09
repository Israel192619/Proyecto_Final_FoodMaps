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
import '../../../config/theme_provider.dart';
import '../../../config/config.dart';
import 'package:cases/constants/restaurant_info_window.dart';
import 'MenuRestPage.dart';

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

  static final LatLng _defaultCenter = LatLng(-17.382202, -66.151789);

  // Guarda el último modo de tema para detectar cambios
  bool? _lastIsDark;
  bool _mapStyleApplied = false;

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

        return Stack(
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
      final url = '${AppConfig.apiBaseUrl}${AppConfig.restaurantesClienteEndpoint}';
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
        print('[MAPS_PAGE] Decodificado data: $data');
        final List restaurantes = data is List ? data : (data['restaurantes'] ?? []);
        print('[MAPS_PAGE] Restaurantes extraídos: $restaurantes');
        _markers.clear();
        _restaurantesData = [];
        for (var obj in restaurantes) {
          print('[MAPS_PAGE] Procesando restaurante: $obj');
          // Agrega SIEMPRE a la tabla
          _restaurantesData.add(obj);

          final lat = obj['latitud'] != null ? double.tryParse(obj['latitud'].toString()) : null;
          final lng = obj['longitud'] != null ? double.tryParse(obj['longitud'].toString()) : null;
          final estado = obj['estado'] is int ? obj['estado'] : int.tryParse(obj['estado'].toString()) ?? 1;
          if (lat == null || lng == null) {
            print('[MAPS_PAGE] Restaurante sin coordenadas, solo tabla.');
            continue;
          }

          final markerId = MarkerId(obj['id'].toString());
          final icon = BitmapDescriptor.defaultMarkerWithHue(
            estado == 0 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
          );

          final position = LatLng(lat, lng);
          _markers.add(
            Marker(
              markerId: markerId,
              position: position,
              icon: icon,
              onTap: () {
                infoPositions = [position];
                infoWidgets = [_buildCustomInfoWindow(obj)];
                setState(() {});
                _customController.addInfoWindow!(infoWidgets, infoPositions);
              },
            ),
          );
        }
        print('[MAPS_PAGE] Total restaurantes agregados a _restaurantesData: ${_restaurantesData.length}');
        setState(() {});
      } else {
        print('[MAPS_PAGE] Error al obtener restaurantes: ${response.statusCode}');
      }
    } catch (e) {
      print('[MAPS_PAGE] Excepción al obtener restaurantes: $e');
    }
  }

  Widget _buildCustomInfoWindow(Map<String, dynamic> restaurantData) {
    return RestaurantInfoWindow(
      restaurantData: restaurantData,
      onMenuPressed: () => _openDetail(restaurantData),
    );
  }

  Future<void> _animateTo(double lat, double lng, double zoom) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(lat, lng), zoom: zoom)),
      );
    }
  }

  void _openDetail(Map obj) {
    // Corrige los campos para evitar errores de tipo
    final int restaurantId = obj['restaurante_id'] is int
        ? obj['restaurante_id']
        : (obj['id'] is int
            ? obj['id']
            : int.tryParse(obj['restaurante_id']?.toString() ?? obj['id']?.toString() ?? '0') ?? 0);
    final String name = obj['nom_rest'] ?? obj['nombre_restaurante'] ?? '';
    final String phone = obj['celular']?.toString() ?? '';
    final String imageUrl = obj['imagen']?.toString() ?? ''; // <-- Asegura que sea String, no String?

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuRestPage(
          restaurantId: restaurantId,
          name: name,
          phone: phone,
          imageUrl: imageUrl,
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    // Usa el widget extraído para la tabla de escritorio
    return MapsDesktopTable(
      restaurantesData: _restaurantesData,
      onMenuPressed: _openDetail,
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}

class MapsDesktopTable extends StatelessWidget {
  final List<Map<String, dynamic>> restaurantesData;
  final void Function(Map<String, dynamic>)? onMenuPressed;

  const MapsDesktopTable({
    Key? key,
    required this.restaurantesData,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardWidth = screenWidth < 1000 ? screenWidth * 0.95 : 900;
    final double cardHeight = screenHeight < 700 ? screenHeight * 0.8 : 500;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurantes'),
        centerTitle: true,
        backgroundColor: isDark ? Colors.black : Colors.red.shade700,
        elevation: 2,
      ),
      body: restaurantesData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: double.infinity,
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
                child: Card(
                  elevation: 10,
                  margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
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
                                    columns: const [
                                      DataColumn(label: Text('Logo', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Ver Menú', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: restaurantesData.map((rest) {
                                      final imageUrl = rest['imagen'];
                                      final nombre = rest['nombre_restaurante'] ?? '';
                                      final ubicacion = rest['ubicacion'] ?? '';
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: imageUrl != null && imageUrl.toString().isNotEmpty
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
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.location_on, size: 18, color: Colors.red),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    ubicacion,
                                                    style: TextStyle(
                                                      color: isDark ? Colors.grey[300] : Colors.grey[800],
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
                            );
                          },
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
