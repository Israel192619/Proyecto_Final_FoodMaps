import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Importar las páginas necesarias
import 'package:cases/screens/dueño/fragments/maps_due_page.dart' show MapsDuePage;
import 'package:cases/screens/dueño/fragments/dueno_platos.dart';
import 'package:cases/screens/dueño/fragments/dueno_bebidas.dart';
import 'package:cases/screens/dueño/fragments/settings_dueno_fragment.dart';
import 'package:cases/config/config.dart';

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

  // --- NUEVO: Variable para saber si está cargando el estado ---
  bool _isLoadingRestauranteStatus = true;
  // NUEVO: Variable para bloquear el switch durante el cambio de estado
  bool _isChangingStatus = false;

  // Instancia única de cada fragment/page
  late final MapsDuePage _mapsDuePage;
  late final PlatosDuenoPage _platosDuenoPage;
  late final BebidasDuenoPage _bebidasDuenoPage;
  late final SettingsDuenoPage _settingsDuenoPage;
  late final List<Widget> _pages;

  // Guarda la referencia al estado de MapsDuePage
  final GlobalKey<State<StatefulWidget>> _mapsDuePageKey = GlobalKey<State<StatefulWidget>>();

  @override
  void initState() {
    super.initState();
    _mapsDuePage = MapsDuePage(
      key: _mapsDuePageKey,
      restauranteId: widget.restauranteId,
    );
    _platosDuenoPage = PlatosDuenoPage(restauranteId: widget.restauranteId);
    _bebidasDuenoPage = BebidasDuenoPage(restauranteId: widget.restauranteId);
    _settingsDuenoPage = SettingsDuenoPage(restauranteId: widget.restauranteId);

    _pages = [
      _mapsDuePage,
      _platosDuenoPage,
      _bebidasDuenoPage,
      _settingsDuenoPage,
    ];

    _fetchRestaurantData();
  }

  Future<void> _fetchRestaurantData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final restauranteId = widget.restauranteId;
    final url = AppConfig.getApiUrl(AppConfig.restauranteStatusEndpoint(restauranteId));
    print('[SWITCH] Consultando estado real en: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[SWITCH] Respuesta statusCode: ${response.statusCode}');
      print('[SWITCH] Respuesta body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final restData = data['data'];
        setState(() {
          _nombreRestaurante = restData['nombre_restaurante'] ?? 'Restaurante';
          _restauranteStatus = restData['estado'] ?? 0;
          _isLoadingRestauranteStatus = false; // --- Estado cargado ---
        });
        // Notifica al fragmento del mapa el estado inicial
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('[MARCADOR] Notificando a MapsDuePage con estado inicial $_restauranteStatus');
          if (_mapsDuePageKey.currentState != null) {
            final dynamic state = _mapsDuePageKey.currentState;
            if (state != null && state.actualizarEstadoRestaurante != null) {
              state.actualizarEstadoRestaurante(_restauranteStatus);
              print('[MARCADOR] Llamada a actualizarEstadoRestaurante desde _fetchRestaurantData');
            }
          }
        });
        print('[SWITCH] Estado real obtenido del backend: $_restauranteStatus');
      } else {
        print('[SWITCH] No se pudo obtener el estado real, usando cerrado (0)');
        setState(() {
          _restauranteStatus = 0;
          _isLoadingRestauranteStatus = false; // --- Estado cargado ---
        });
      }
    } catch (e) {
      print('[SWITCH] Error al consultar estado real: $e');
      setState(() {
        _restauranteStatus = 0;
        _isLoadingRestauranteStatus = false; // --- Estado cargado ---
      });
    }
  }

  Future<void> _cambiarEstadoRestaurante(bool _) async {
    setState(() {
      _isChangingStatus = true; // Bloquea el switch
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final restauranteId = widget.restauranteId;

    final url = AppConfig.getApiUrl(AppConfig.restauranteChangeStatusEndpoint(restauranteId));
    print('[SWITCH] Enviando POST a: $url');
    print('[SWITCH] Datos enviados: estado_actual=$_restauranteStatus');
    print('[SWITCH] Token: $token');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'estado_actual': _restauranteStatus}),
      );

      print('[SWITCH] Respuesta statusCode: ${response.statusCode}');
      print('[SWITCH] Respuesta body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final nuevoEstado = responseData['data']?['estado'] ?? (_restauranteStatus == 1 ? 0 : 1);

        setState(() {
          _restauranteStatus = nuevoEstado;
        });
        // Notifica al fragmento del mapa el nuevo estado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print('[MARCADOR] Notificando a MapsDuePage con nuevo estado $_restauranteStatus');
          if (_mapsDuePageKey.currentState != null) {
            final dynamic state = _mapsDuePageKey.currentState;
            if (state != null && state.actualizarEstadoRestaurante != null) {
              state.actualizarEstadoRestaurante(_restauranteStatus);
              print('[MARCADOR] Llamada a actualizarEstadoRestaurante desde _cambiarEstadoRestaurante');
            }
          }
        });
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] is Map && data['data']['estado_real'] != null) {
          setState(() {
            _restauranteStatus = data['data']['estado_real'];
            print('[SWITCH] Estado después de error 400: $_restauranteStatus (${_restauranteStatus == 1 ? 'Abierto' : 'Cerrado'})');
          });
          print('[MARCADOR] Notificando a MapsDuePage con estado error $_restauranteStatus');
          if (_mapsDuePageKey.currentState != null) {
            final dynamic state = _mapsDuePageKey.currentState;
            if (state != null && state.actualizarEstadoRestaurante != null) {
              state.actualizarEstadoRestaurante(_restauranteStatus);
              print('[MARCADOR] Llamada a actualizarEstadoRestaurante desde error 400');
            }
          }
        }
        print('[SWITCH] Error al actualizar estado: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'No se pudo cambiar el estado.')),
        );
      } else {
        print('[MAPS_DUE_ACTIVITY] Error al actualizar estado: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cambiar el estado.')),
        );
      }
    } catch (e) {
      print('[MAPS_DUE_ACTIVITY] Excepción al cambiar estado: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión al cambiar estado.')),
      );
    } finally {
      setState(() {
        _isChangingStatus = false; // Desbloquea el switch
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[BUILD] Rebuild de MapsDueActivity. Estado actual: $_restauranteStatus');
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
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
    print('[SWITCH] Valor inicial del switch: $_restauranteStatus (${_restauranteStatus == 1 ? 'Abierto' : 'Cerrado'})');
    // --- NUEVO: Mostrar indicador de carga si está cargando el estado ---
    if (_isLoadingRestauranteStatus) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
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
          onChanged: _isChangingStatus
              ? null // Deshabilita el switch mientras cambia el estado
              : (value) {
                  print('[SWITCH] Switch presionado. Valor actual: $_restauranteStatus (${_restauranteStatus == 1 ? 'Abierto' : 'Cerrado'}), valor del switch: $value');
                  _cambiarEstadoRestaurante(value);
                },
          activeColor: Colors.green,
          inactiveThumbColor: Colors.red,
        ),
        if (_isChangingStatus)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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