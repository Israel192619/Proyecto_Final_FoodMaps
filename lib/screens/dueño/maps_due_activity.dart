import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Importar las páginas necesarias
import 'package:cases/screens/dueño/fragments/maps_due_page.dart';
import 'package:cases/screens/dueño/fragments/dueno_platos.dart';
import 'package:cases/screens/dueño/fragments/dueno_bebidas.dart';
import 'package:cases/screens/dueño/fragments/settings_dueno_fragment.dart';

class MapsDueActivity extends StatefulWidget {
  final int restauranteId;

  const MapsDueActivity({Key? key, required this.restauranteId}) : super(key: key);

  @override
  _VistaDuenoState createState() => _VistaDuenoState();
}

class _VistaDuenoState extends State<MapsDueActivity> {
  int _currentIndex = 0;
  int _restauranteStatus = 0;
  String _nombreRestaurante = '';
  String _imagenRestaurante = '';
  late GoogleMapController _mapController;
  int _contadorVistas = 0;

  // Instancia única de cada fragment/page
  late final MapsDuePage _mapsDuePage;
  late final PlatosDuenoPage _platosDuenoPage;
  late final BebidasDuenoPage _bebidasDuenoPage;
  late final SettingsDuenoPage _settingsDuenoPage;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _guardarSesion();
    _fetchRestaurantData();

    // Instanciar solo una vez
    _mapsDuePage = MapsDuePage(restauranteId: widget.restauranteId);
    _platosDuenoPage = PlatosDuenoPage(restauranteId: widget.restauranteId);
    _bebidasDuenoPage = BebidasDuenoPage(restauranteId: widget.restauranteId);
    _settingsDuenoPage = SettingsDuenoPage(restauranteId: widget.restauranteId);

    _pages = [
      _mapsDuePage,
      _platosDuenoPage,
      _bebidasDuenoPage,
      _settingsDuenoPage,
    ];
  }

  Future<void> _guardarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mantenersesion', true);
    await prefs.setInt('restaurante_id', widget.restauranteId);
  }

  Future<void> _fetchRestaurantData() async {
    final prefs = await SharedPreferences.getInstance();
    final restauranteJson = prefs.getString('restaurante_seleccionado');
    if (restauranteJson != null) {
      try {
        final restaurante = jsonDecode(restauranteJson);
        setState(() {
          _nombreRestaurante = restaurante['nombre_restaurante'] ?? 'Restaurante';
          _imagenRestaurante = restaurante['imagen'] ?? '';
          _restauranteStatus = restaurante['estado'] ?? 1;
          _contadorVistas = restaurante['contador_vistas'] ?? 0;
        });
        print('[MAPS_DUE_ACTIVITY] Datos del restaurante cargados de SharedPreferences: $_nombreRestaurante, $_imagenRestaurante, $_restauranteStatus, $_contadorVistas');
        return;
      } catch (e) {
        print('[MAPS_DUE_ACTIVITY] Error al decodificar restaurante_seleccionado: $e');
      }
    }

    // Fallback simulado si no hay datos en SharedPreferences
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _nombreRestaurante = 'Restaurante Ejemplo';
      _imagenRestaurante = 'https://i.etsystatic.com/59767526/r/il/bf8743/6912133860/il_fullxfull.6912133860_bbme.jpg';
      _restauranteStatus = 1;
      _contadorVistas = 123;
    });
  }

  Future<void> _cambiarEstadoRestaurante(bool isOpen) async {
    final nuevoEstado = isOpen ? 1 : 0;
    // Simular llamada API para cambiar estado
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _restauranteStatus = nuevoEstado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Quita el botón de retroceso
          title: Row(
            children: [
              // Logo del restaurante
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _imagenRestaurante.isNotEmpty
                    ? Image.network(
                        _imagenRestaurante,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
                      )
                    : const Icon(Icons.image, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombreRestaurante,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye, size: 18, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '$_contadorVistas vistas',
                          style: const TextStyle(fontSize: 14, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            _buildStatusSwitch(),
          ],
        ),
        // Cambia aquí: usa IndexedStack para mantener el estado de los fragments/pages
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.food_bank),
              label: 'Alimentos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_drink),
              label: 'Bebidas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSwitch() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _restauranteStatus == 1 ? 'Abierto' : 'Cerrado',
          style: TextStyle(
            color: _restauranteStatus == 1 ? Colors.green : Colors.red,
          ),
        ),
        Switch(
          value: _restauranteStatus == 1,
          onChanged: _cambiarEstadoRestaurante,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
        ),
      ],
    );
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir?'),
        content: const Text('¿Estás seguro que quieres salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }
}