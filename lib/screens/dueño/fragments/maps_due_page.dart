// maps_due_page.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import '../../../config/config.dart';
import '../../../config/theme_provider.dart';
import '../../cliente/fragments/maps_page.dart'; // Importa MapsDesktopTable

class MapsDuePage extends StatefulWidget {
  final int restauranteId;

  const MapsDuePage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  _MapsDuePageState createState() => _MapsDuePageState();
}

class _MapsDuePageState extends State<MapsDuePage> {
  GoogleMapController? _mapController;
  LatLng _defaultPosition = LatLng(-17.382202, -66.151789); // Cochabamba por defecto
  Marker? _restauranteMarker;
  int _restauranteStatus = 1;

  bool? _lastIsDark;
  bool _mapStyleApplied = false;

  bool _hasCoordenadas = false;

  Set<Marker> _allMarkers = {};
  List<Map<String, dynamic>> _restaurantesData = [];

  @override
  void initState() {
    super.initState();
    _setInitialPosition();
    _fetchRestaurantData();
    _fetchLocationsFromApi(); // Cambia a la lógica de maps_page
  }

  Future<void> _setInitialPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final restauranteJson = prefs.getString('restaurante_seleccionado');
    if (restauranteJson != null) {
      try {
        final restaurante = jsonDecode(restauranteJson);
        if (restaurante['latitud'] != null && restaurante['longitud'] != null) {
          final lat = double.tryParse(restaurante['latitud'].toString());
          final lng = double.tryParse(restaurante['longitud'].toString());
          if (lat != null && lng != null) {
            setState(() {
              _defaultPosition = LatLng(lat, lng);
              _hasCoordenadas = true;
            });
            print('[MAPS_DUE_PAGE] Centrado en ubicación guardada: $_defaultPosition');
            return;
          }
        }
      } catch (e) {
        print('[MAPS_DUE_PAGE] Error al decodificar restaurante_seleccionado: $e');
      }
    }
    setState(() {
      _hasCoordenadas = false;
    });
    print('[MAPS_DUE_PAGE] Usando ubicación por defecto (Cochabamba)');
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

  Future<void> _fetchRestaurantData() async {
    await Future.delayed(Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    final restauranteJson = prefs.getString('restaurante_seleccionado');
    LatLng? latLng;
    String nombre = 'Restaurante Ejemplo';

    if (restauranteJson != null) {
      try {
        final restaurante = jsonDecode(restauranteJson);
        if (restaurante['latitud'] != null && restaurante['longitud'] != null) {
          final lat = double.tryParse(restaurante['latitud'].toString());
          final lng = double.tryParse(restaurante['longitud'].toString());
          if (lat != null && lng != null) {
            latLng = LatLng(lat, lng);
          }
        }
        if (restaurante['nombre_restaurante'] != null) {
          nombre = restaurante['nombre_restaurante'];
        }
      } catch (e) {
        print('[MAPS_DUE_PAGE] Error al decodificar restaurante_seleccionado en fetch: $e');
      }
    }

    setState(() {
      _restauranteStatus = 1;
      if (latLng != null) {
        _restauranteMarker = Marker(
          markerId: MarkerId(widget.restauranteId.toString()),
          position: latLng,
          infoWindow: InfoWindow(title: nombre),
          icon: _restauranteStatus == 1
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      } else {
        _restauranteMarker = null;
      }
    });
  }

  // Reemplaza _fetchAllRestaurants por la lógica de maps_page
  Future<void> _fetchLocationsFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('[MAPS_DUE_PAGE] _fetchLocationsFromApi llamado. token=$token');
    if (token == null) {
      print('[MAPS_DUE_PAGE] No hay token de autenticación');
      return;
    }
    try {
      final url = '${AppConfig.apiBaseUrl}${AppConfig.restaurantesClienteEndpoint}';
      print('[MAPS_DUE_PAGE] Realizando GET a $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[MAPS_DUE_PAGE] Respuesta statusCode: ${response.statusCode}');
      print('[MAPS_DUE_PAGE] Respuesta body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[MAPS_DUE_PAGE] Decodificado data: $data');
        final List restaurantes = data is List ? data : (data['restaurantes'] ?? []);
        print('[MAPS_DUE_PAGE] Restaurantes extraídos: $restaurantes');
        Set<Marker> markers = {};
        List<Map<String, dynamic>> restaurantesDataTmp = [];
        for (var obj in restaurantes) {
          print('[MAPS_DUE_PAGE] Procesando restaurante: $obj');
          // Agrega SIEMPRE a la tabla
          restaurantesDataTmp.add(obj);

          final lat = obj['latitud'] != null ? double.tryParse(obj['latitud'].toString()) : null;
          final lng = obj['longitud'] != null ? double.tryParse(obj['longitud'].toString()) : null;
          final estado = obj['estado'] is int ? obj['estado'] : int.tryParse(obj['estado'].toString()) ?? 1;
          if (lat == null || lng == null) {
            print('[MAPS_DUE_PAGE] Restaurante sin coordenadas, solo tabla.');
            continue;
          }

          final markerId = MarkerId(obj['id'].toString());
          final icon = BitmapDescriptor.defaultMarkerWithHue(
            estado == 0 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
          );

          final position = LatLng(lat, lng);
          markers.add(
            Marker(
              markerId: markerId,
              position: position,
              icon: icon,
              infoWindow: InfoWindow(title: obj['nombre_restaurante'] ?? ''),
            ),
          );
        }
        print('[MAPS_DUE_PAGE] Total restaurantes agregados a _restaurantesData: ${restaurantesDataTmp.length}');
        setState(() {
          _allMarkers = markers;
          _restaurantesData = restaurantesDataTmp;
        });
      } else {
        print('[MAPS_DUE_PAGE] Error al obtener restaurantes: ${response.statusCode}');
      }
    } catch (e) {
      print('[MAPS_DUE_PAGE] Excepción al obtener restaurantes: $e');
    }
  }

  void _updateMarkerStatus(int status) {
    if (_restauranteMarker != null) {
      setState(() {
        _restauranteStatus = status;
        _restauranteMarker = _restauranteMarker!.copyWith(
          iconParam: status == 1
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
         defaultTargetPlatform == TargetPlatform.linux ||
         defaultTargetPlatform == TargetPlatform.macOS);

    print('[MAPS_DUE_PAGE] Plataforma detectada: ${defaultTargetPlatform.toString()}, isDesktop=$isDesktop, kIsWeb=$kIsWeb');
    print('[MAPS_DUE_PAGE] _restaurantesData.length=${_restaurantesData.length}');

    if (isDesktop) {
      print('[MAPS_DUE_PAGE] Mostrando tabla de restaurantes en escritorio');
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

        Set<Marker> markersToShow = {..._allMarkers};
        if (_restauranteMarker != null) {
          markersToShow.add(_restauranteMarker!);
        }
        return GoogleMap(
          onMapCreated: (controller) async {
            print('[MAP_STYLE] onMapCreated llamado');
            _mapController = controller;
            _mapStyleApplied = false;
            await _applyMapStyle(themeProvider.isDarkMode);
            // Centrar el mapa en la ubicación guardada si existe
            _mapController?.moveCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: _defaultPosition, zoom: 15),
              ),
            );
          },
          initialCameraPosition: CameraPosition(target: _defaultPosition, zoom: 15),
          markers: markersToShow,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        );
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    // Reutiliza el widget de tabla de escritorio de maps_page
    return MapsDesktopTable(restaurantesData: _restaurantesData);
  }
}
