import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_custom_windows/google_map_custom_windows.dart';

class CustomInfoWindowController {
  final GoogleMapCustomWindowController customController = GoogleMapCustomWindowController();
  GoogleMapController? googleMapController;

  void initialize(GoogleMapController mapController) {
    googleMapController = mapController;
    customController.googleMapController = googleMapController;
  }

  void showInfoWindow(List<Widget> widgets, List<LatLng> positions) {
    customController.addInfoWindow!(widgets, positions);
  }

  void hideInfoWindow() {
    customController.hideInfoWindow!();
  }

  void dispose() {
    customController.dispose();
  }
}