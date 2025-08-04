// maps_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_custom_windows/google_map_custom_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../../../config/theme_provider.dart';
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

  static final LatLng _defaultCenter = LatLng(-17.382202, -66.151789);

  // Guarda el último modo de tema para detectar cambios
  bool? _lastIsDark;
  bool _mapStyleApplied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndFetch();
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

    _fetchLocations();
  }

  @override
  Widget build(BuildContext context) {
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

  Future<void> _fetchLocations() async {
    final data = [
      {
        'restaurante_id': 1,
        'latitud': -17.383333,
        'longitud': -66.15,
        'nom_rest': 'Restaurante de Prueba',
        'estado': 1,
        'imagen': 'https://i.etsystatic.com/59767526/r/il/bf8743/6912133860/il_fullxfull.6912133860_bbme.jpg',
        'celular': '76543210',
      },
    ];

    for (var obj in data) {
      final lat = obj['latitud'] as double;
      final lng = obj['longitud'] as double;
      final estado = obj['estado'] as int;

      final markerId = MarkerId(obj['restaurante_id'].toString());
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
    setState(() {});
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuRestPage(
          restaurantId: obj['restaurante_id'],
          name: obj['nom_rest'],
          phone: obj['celular'].toString(),
          imageUrl: obj['imagen'],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}
