// maps_due_page.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../config/theme_provider.dart';

class MapsDuePage extends StatefulWidget {
  final int restauranteId;

  const MapsDuePage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  _MapsDuePageState createState() => _MapsDuePageState();
}

class _MapsDuePageState extends State<MapsDuePage> {
  GoogleMapController? _mapController;
  final LatLng _defaultPosition = LatLng(-17.382202, -66.151789);
  Marker? _restauranteMarker;
  int _restauranteStatus = 1;

  bool? _lastIsDark;
  bool _mapStyleApplied = false;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantData();
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
    final latLng = LatLng(-17.383333, -66.15);
    final nombre = 'Restaurante Ejemplo';

    setState(() {
      _restauranteStatus = 1;
      _restauranteMarker = Marker(
        markerId: MarkerId(widget.restauranteId.toString()),
        position: latLng,
        infoWindow: InfoWindow(title: nombre),
        icon: _restauranteStatus == 1
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    });
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        // Aplica el estilo si el controlador ya existe y el tema cambió o nunca se aplicó
        if (_mapController != null &&
            (_lastIsDark != themeProvider.isDarkMode || !_mapStyleApplied)) {
          print('[MAP_STYLE] build() detecta cambio de tema o estilo no aplicado');
          _applyMapStyle(themeProvider.isDarkMode);
        }
        _lastIsDark = themeProvider.isDarkMode;

        return GoogleMap(
          onMapCreated: (controller) async {
            print('[MAP_STYLE] onMapCreated llamado');
            _mapController = controller;
            _mapStyleApplied = false;
            await _applyMapStyle(themeProvider.isDarkMode);
          },
          initialCameraPosition: CameraPosition(target: _defaultPosition, zoom: 15),
          markers: _restauranteMarker != null ? {_restauranteMarker!} : {},
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        );
      },
    );
  }
}
