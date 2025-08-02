import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_custom_windows/google_map_custom_windows.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:http/http.dart' as http;

import 'MenuRestPage.dart';

class MapsPage extends StatefulWidget {
  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  GoogleMapController? _mapController;
  final customController = GoogleMapCustomWindowController();
  final Set<Marker> _markers = {};
  List<LatLng> infoPositions = [];
  List<Widget> infoWidgets = [];

  static final LatLng _defaultCenter = LatLng(-17.382202, -66.151789);

  String? _mapStyle;
  Timer? _webStyleTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndFetch();
    _loadMapStyle();
  }

  bool _isWebStyleApplied = false;

  Future<void> _loadMapStyle() async {
    try {
      if (kIsWeb) {
        final response = await http.get(Uri.parse('/assets/map_styles/map_style_no_labels.json'));
        if (response.statusCode == 200) {
          _mapStyle = response.body;
          print("✅ Estilo cargado desde web correctamente");
          print(_mapStyle); // <- esto es clave
        }
        else {
          print("Error cargando estilo desde web: ${response.statusCode}");
        }
      } else {
        _mapStyle = await rootBundle.loadString('assets/map_styles/map_style_no_labels.json');
      }

      if (_mapController != null) {
        _mapController!.setMapStyle(_mapStyle);
      }
    } catch (e) {
      print('Error loading map style: $e');
    }
  }

  void _applyWebMapStyle() {
    if (_mapController == null || _mapStyle == null || _isWebStyleApplied) return;

    // Intenta aplicar el estilo inmediatamente
    _mapController!.setMapStyle(_mapStyle).then((_) {
      _isWebStyleApplied = true;
    }).catchError((_) {
      // Si falla, reintenta después de un delay
      Future.delayed(Duration(milliseconds: 500), () {
        _applyWebMapStyle();
      });
    });
  }

  // Verifica permisos de ubicación y obtiene la posición actual
  Future<void> _checkPermissionAndFetch() async {
    if (await Permission.location.request().isGranted) {
      Position pos = await Geolocator.getCurrentPosition();
      _animateTo(pos.latitude, pos.longitude, 17);
    }
    _fetchLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) async {
            _mapController = controller;
            customController.googleMapController = controller;

            if (_mapStyle != null) {
              if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
                _mapController!.setMapStyle(_mapStyle);
              } else if (kIsWeb) {
                _applyWebMapStyle();
              }
            }
          },
          initialCameraPosition: CameraPosition(target: _defaultCenter, zoom: 15),
          markers: _markers,
          myLocationEnabled: true,
          onTap: (_) => customController.hideInfoWindow!(),
          onCameraMove: (_) => customController.onCameraMove!(),
        ),
        CustomMapInfoWindow(
          controller: customController,
          offset: Offset(0, 50),
          height: 150,
          width: 200,
        ),
      ],
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
        'imagen': 'https://via.placeholder.com/150',
        'celular': '76543210',
      },
    ];

    for (var obj in data) {
      final lat = obj['latitud'] as double;
      final lng = obj['longitud'] as double;
      final title = obj['nom_rest'] as String;
      final estado = obj['estado'] as int;
      final imageUrl = obj['imagen'] as String;

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
            infoWidgets = [
              GestureDetector(
                onTap: () => _openDetail(obj),
                child: Card(
                  child: Column(
                    children: [
                      Image.network(imageUrl, height: 80, fit: BoxFit.cover),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              )
            ];
            setState(() {});
            customController.addInfoWindow!(infoWidgets, infoPositions);
          },
        ),
      );
    }
    setState(() {});
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
      MaterialPageRoute(builder: (_) => MenuRestPage(
        restaurantId: obj['restaurante_id'],
        name: obj['nom_rest'],
        phone: obj['celular'].toString(),
        imageUrl: obj['imagen'],
      )),
    );
  }

  @override
  void dispose() {
    customController.dispose();
    _webStyleTimer?.cancel();
    super.dispose();
  }
}
