import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsDuePage extends StatefulWidget {
  final int restauranteId;

  const MapsDuePage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  _MapsDuePageState createState() => _MapsDuePageState();
}

class _MapsDuePageState extends State<MapsDuePage> {
  late GoogleMapController _mapController;
  final LatLng _defaultPosition = LatLng(-17.382202, -66.151789);
  Marker? _restauranteMarker;
  int _restauranteStatus = 1;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantData();
  }

  Future<void> _fetchRestaurantData() async {
    // Simular llamada API para obtener datos del restaurante
    await Future.delayed(Duration(seconds: 1));

    final latLng = LatLng(-17.383333, -66.15);
    final nombre = 'Restaurante Ejemplo';

    setState(() {
      _restauranteStatus = 1; // 1 para abierto, 0 para cerrado
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
    return GoogleMap(
      onMapCreated: (controller) {
        _mapController = controller;
        // Aplicar estilo personalizado al mapa si es necesario
      },
      initialCameraPosition: CameraPosition(
        target: _defaultPosition,
        zoom: 15,
      ),
      markers: _restauranteMarker != null ? {_restauranteMarker!} : {},
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
    );
  }
}