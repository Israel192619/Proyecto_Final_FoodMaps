import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _buildPlatformSpecificMap(),
    );
  }

  Widget _buildPlatformSpecificMap() {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return const GoogleMapView();
    } else {
      return const UnsupportedPlatformView();
    }
  }
}

class GoogleMapView extends StatefulWidget {
  const GoogleMapView({super.key});

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  bool _isMapCreated = false;
  static const LatLng _initialPosition = LatLng(-17.3895, -66.1568); // Cochabamba
  static const double _initialZoom = 14.0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _initialPosition,
            zoom: _initialZoom,
          ),
          onMapCreated: (controller) {
            setState(() {
              _controller = controller;
              _isMapCreated = true;
              _addInitialMarker();
            });
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          onCameraMove: (position) {
            // Puedes agregar lógica para mover marcadores aquí
          },
          compassEnabled: true,
          mapToolbarEnabled: true,
        ),

        if (!_isMapCreated)
          const Center(child: CircularProgressIndicator()),

        // Botón personalizado para centrar el mapa
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _centerMap,
            child: const Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }

  void _addInitialMarker() {
    setState(() {
      _markers.add(
          Marker(
            markerId: const MarkerId('cochabamba_center'),
            position: _initialPosition,
            infoWindow: const InfoWindow(
              title: 'Cochabamba',
              snippet: 'Centro de la ciudad',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          )
      );
    });
  }

  Future<void> _centerMap() async {
    if (_controller != null) {
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: _initialPosition,
            zoom: _initialZoom,
          ),
        ),
      );
    }
  }
}

class UnsupportedPlatformView extends StatelessWidget {
  const UnsupportedPlatformView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 50, color: Colors.blue),
          const SizedBox(height: 20),
          Text(
            'Función de mapa no disponible',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          const Text(
            'Esta funcionalidad solo está disponible en dispositivos móviles y web.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              // Acción alternativa, como abrir Google Maps en el navegador
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Abrir en navegador'),
          ),
        ],
      ),
    );
  }
}