import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_custom_windows/google_map_custom_windows.dart';

class CustomInfoWindowController {
  late GoogleMapCustomWindowController customController;
  late GoogleMapController googleMapController;

  void initialize(GoogleMapController mapController) {
    customController = GoogleMapCustomWindowController();
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