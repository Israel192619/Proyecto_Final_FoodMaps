import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart'; // <-- Corrige el import eliminando el espacio extra

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

class _VistaDuenoState extends State<MapsDueActivity> with WidgetsBindingObserver {
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

  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Escucha cambios de ciclo de vida
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
    _connectWebSocketChannel();
  }

  Future<void> _fetchRestaurantData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final restauranteId = widget.restauranteId;
    final url = AppConfig.getApiUrl(AppConfig.restauranteStatusEndpoint(restauranteId));
    print('[WSO][RUTA] GET estado restaurante: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[WSO] Respuesta statusCode: ${response.statusCode}');
      print('[WSO] Respuesta body: ${response.body}');
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
        print('[WSO] Estado real obtenido del backend: $_restauranteStatus');
      } else {
        print('[WSO] No se pudo obtener el estado real, usando cerrado (0)');
        setState(() {
          _restauranteStatus = 0;
          _isLoadingRestauranteStatus = false; // --- Estado cargado ---
        });
      }
    } catch (e) {
      print('[WSO] Error al consultar estado real: $e');
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
    print('[WSO][RUTA] POST cambiar estado restaurante: $url');
    print('[WSO] Datos enviados: estado_actual=$_restauranteStatus');
    print('[WSO] Token: $token');

    // ❌ ELIMINADO: No enviar mensajes por WebSocket para cambiar estado

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'estado_actual': _restauranteStatus}),
      );

      print('[WSO] Respuesta statusCode: ${response.statusCode}');
      print('[WSO] Respuesta body: ${response.body}');

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
            print('[WSO] Estado después de error 400: $_restauranteStatus (${_restauranteStatus == 1 ? 'Abierto' : 'Cerrado'})');
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
        print('[WSO] Error al actualizar estado: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'No se pudo cambiar el estado.')),
        );
      } else {
        print('[WSO] Error al actualizar estado: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cambiar el estado.')),
        );
      }
    } catch (e) {
      print('[WSO] Excepción al cambiar estado: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión al cambiar estado.')),
      );
    } finally {
      setState(() {
        _isChangingStatus = false; // Desbloquea el switch
      });
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    print('[WSO] Procesando mensaje WebSocket: $message');
    try {
      final data = jsonDecode(message);

      switch (data['event']) {
        case 'status.updated':
          print('[WSO] Evento status.updated recibido: ${data['data']}');
          _handleRestaurantStatusUpdate(data['data']);
          break;
        case 'pusher:ping':
          print('[WSO] Recibido pusher:ping, enviando pusher:pong');
          _channel?.sink.add(jsonEncode({'event': 'pusher:pong', 'data': {}}));
          break;
        default:
          print('[WSO] Evento no manejado: ${data['event']}');
      }
    } catch (e) {
      print('[WSO] Error al procesar mensaje WebSocket: $e');
    }
  }

  void _handleRestaurantStatusUpdate(dynamic eventData) {
    Map<String, dynamic>? parsed;
    if (eventData is String) {
      try {
        parsed = jsonDecode(eventData);
      } catch (e) {
        print('[WSO] Error al decodificar eventData: $e');
        return;
      }
    } else if (eventData is Map<String, dynamic>) {
      parsed = eventData;
    }

    if (parsed != null && parsed.containsKey('id') && parsed.containsKey('estado')) {
      final id = parsed['id'];
      final estado = parsed['estado'];
      print('[WSO] Actualizando estado desde WebSocket para restaurante_id=$id, estado=$estado');
      // --- CAMBIO: Llama directamente al método de actualización ---
      if (_mapsDuePageKey.currentState != null) {
        final dynamic state = _mapsDuePageKey.currentState;
        if (state != null && state.actualizarMarcadorRestaurantePorId != null) {
          print('[WSO] Llamando a actualizarMarcadorRestaurantePorId desde WebSocket para id=$id, estado=$estado');
          state.actualizarMarcadorRestaurantePorId(id, estado);
        }
      }
      // Solo si el evento corresponde al restaurante principal, actualiza el switch y el marcador principal
      if (id == widget.restauranteId) {
        setState(() {
          _restauranteStatus = estado;
        });
        if (_mapsDuePageKey.currentState != null) {
          final dynamic state = _mapsDuePageKey.currentState;
          if (state != null && state.actualizarEstadoRestaurante != null) {
            print('[WSO] Llamando a actualizarEstadoRestaurante desde WebSocket con estado $_restauranteStatus');
            state.actualizarEstadoRestaurante(_restauranteStatus);
          }
        }
      } else {
        print('[WSO] Solo se actualiza el color del marcador en el mapa para restaurante_id=$id');
      }
    } else {
      print('[WSO] eventData no contiene los campos necesarios: $parsed');
    }
  }

  void _connectWebSocketChannel() {
    final wsUrl = AppConfig.getWebSocketUrl();
    print('[WSO][RUTA] WebSocket: $wsUrl');
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    final subscribeMsg = {
      "event": "pusher:subscribe",
      "data": {
        "channel": "restaurants"
      }
    };
    print('[WSO] Enviando mensaje de suscripción: $subscribeMsg');
    _channel?.sink.add(jsonEncode(subscribeMsg));

    _channel?.stream.listen(
      (message) {
        print('[WSO] Mensaje recibido del WebSocket: $message');
        try {
          final data = jsonDecode(message);
          print('[WSO] Decodificado: $data');
          if (data is Map && data.containsKey('event')) {
            print('[WSO] Evento recibido: ${data['event']}');
            if (data['event'] == 'status.updated') {
              print('[WSO] Evento status.updated recibido: ${data['data']}');
              _handleRestaurantStatusUpdate(data['data']);
            } else if (data['event'] == 'pusher:ping') {
              print('[WSO] Recibido pusher:ping, enviando pusher:pong');
              _channel?.sink.add(jsonEncode({'event': 'pusher:pong', 'data': {}}));
            } else if (data['event'] == 'pusher_internal:subscription_succeeded') {
              print('[WSO] Suscripción exitosa al canal: ${data['channel']}');
            } else {
              print('[WSO] Evento no relevante para estado: ${data['event']}');
            }
          } else {
            print('[WSO] Mensaje recibido sin campo "event": $data');
          }
        } catch (e) {
          print('[WSO] Error al procesar mensaje WebSocket: $e');
        }
      },
      onError: (error) {
        print('[WSO] Error en la conexión WebSocket: $error');
      },
      onDone: () {
        print('[WSO] Conexión WebSocket cerrada');
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Deja de escuchar
    _channel?.sink.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[WSO] didChangeAppLifecycleState: $state');
    if (state == AppLifecycleState.resumed) {
      print('[WSO] App reanudada, reconectando WebSocket y refrescando datos');
      _connectWebSocketChannel();
      _fetchRestaurantData();
      // Refresca los restaurantes en el mapa (actualiza todos los marcadores)
      if (_mapsDuePageKey.currentState != null) {
        final dynamic state = _mapsDuePageKey.currentState;
        if (state != null && state._fetchLocationsFromApi != null) {
          print('[WSO] Refrescando todos los marcadores del mapa por reanudación');
          state._fetchLocationsFromApi();
        }
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      print('[WSO] App en segundo plano o bloqueada, cerrando WebSocket');
      _channel?.sink.close();
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
    print('[WSO] Valor inicial del switch: $_restauranteStatus (${_restauranteStatus == 1 ? 'Abierto' : 'Cerrado'})');
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
                  print('[WSO] Switch presionado. Valor actual: $_restauranteStatus (${_restauranteStatus == 1 ? 'Abierto' : 'Cerrado'}), valor del switch: $value');
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
