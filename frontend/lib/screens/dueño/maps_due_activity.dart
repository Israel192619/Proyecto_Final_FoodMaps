import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart'; // <-- Corrige el import eliminando el espacio extra

// Importar las páginas necesarias
import 'package:foodmaps/screens/dueño/fragments/maps_due_page.dart' show MapsDuePage;
import 'package:foodmaps/screens/dueño/fragments/dueno_platos_page.dart';
import 'package:foodmaps/screens/dueño/fragments/dueno_bebidas_page.dart';
import 'package:foodmaps/screens/dueño/fragments/settings_dueno_page.dart';
import 'package:foodmaps/config/config.dart';

String getRestauranteImageUrl(String? imagen) {
  return AppConfig.getImageUrl(imagen);
}

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

    String nombreRestaurante = 'Restaurante';
    int estadoRestaurante = 0;
    String imagenRestaurante = '';

    // 1. Consulta la lista de restaurantes y busca el restaurante por ID
    final urlLista = AppConfig.getApiUrl(AppConfig.restaurantesClienteEndpoint);
    print('[VISTA][D_IMAGEN] GET lista restaurantes: $urlLista');
    try {
      final response = await http.get(
        Uri.parse(urlLista),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[VISTA][D_IMAGEN] Respuesta lista statusCode: ${response.statusCode}');
      print('[VISTA][D_IMAGEN] Respuesta lista body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List restaurantes = data is Map && data.containsKey('data') ? data['data'] : [];
        final restaurante = restaurantes.firstWhere(
              (r) => r['id'] == restauranteId,
          orElse: () => null,
        );
        print('[VISTA][D_IMAGEN] Restaurante encontrado: $restaurante');
        if (restaurante != null) {
          nombreRestaurante = restaurante['nombre_restaurante'] ?? nombreRestaurante;
          estadoRestaurante = restaurante['estado'] ?? estadoRestaurante;
          imagenRestaurante = restaurante['imagen'] ?? '';
          print('[VISTA][D_IMAGEN] Imagen obtenida: $imagenRestaurante');
        }
      }
    } catch (e) {
      print('[VISTA][D_IMAGEN] Error al obtener lista de restaurantes: $e');
    }

    setState(() {
      _nombreRestaurante = nombreRestaurante;
      _restauranteStatus = estadoRestaurante;
      _imagenRestaurante = imagenRestaurante;
      print('[VISTA][D_IMAGEN] Valor de imagen asignado FINAL: $_imagenRestaurante');
      _isLoadingRestauranteStatus = false;
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
      // --- CAMBIO: Llama directamente al metodo de actualización ---
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
    // Cierra el canal anterior si existe antes de crear uno nuevo
    try {
      if (_channel != null) {
        print('[WSO] Cerrando canal WebSocket anterior antes de reconectar');
        _channel?.sink.close();
        _channel = null;
      }

      final wsUrl = AppConfig.getWebSocketUrl();
      print('[WSO][RUTA] WebSocket: $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      final subscribeMsg = {
        "event": "pusher:subscribe",
        "data": {
          "channel": "restaurantes"
        }
      };
      print('[WSO] Enviando mensaje de suscripción: $subscribeMsg');
      _channel?.sink.add(jsonEncode(subscribeMsg));

      bool suscripcionExitosa = false;

      _channel?.stream.listen(
        (message) {
          print('[WSO] Mensaje recibido del WebSocket: $message');
          try {
            // Resto del código existente
            _handleWebSocketMessage(message);
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
    } catch (e) {
      print('[WSO] Error al configurar WebSocket: $e');
    }
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
      setState(() => _isLoadingRestauranteStatus = true);
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
      _channel = null;
    }
  }

  // Método público para recargar datos del restaurante
  void recargarDatosRestaurante() {
    print('[VISTA MAPSDUE] Recargando datos del restaurante después de edición');

    // Forzar recarga de datos del restaurante (incluida la imagen del banner)
    setState(() {
      // Limpiar imagen actual para evitar cache
      _imagenRestaurante = '';
      _isLoadingRestauranteStatus = true; // Mostrar indicador de carga
    });

    // Asegurarse que tengamos una conexión WebSocket activa
    _connectWebSocketChannel();

    // Cargar datos del restaurante
    _fetchRestaurantData();

    // También refresca el mapa si estamos en la página del mapa
    if (_mapsDuePageKey.currentState != null) {
      final dynamic state = _mapsDuePageKey.currentState;
      if (state != null && state._fetchLocationsFromApi != null) {
        state._fetchLocationsFromApi();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[VISTA MAPSDUE] build MapsDueActivity restauranteId=${widget.restauranteId}');
    print('[VISTA MAPSDUE] Estado actual: _restauranteStatus=$_restauranteStatus');
    SharedPreferences.getInstance().then((prefs) {
      final token = prefs.getString('auth_token');
      final restauranteId = prefs.getInt('restaurante_id');
      final restaurantes = prefs.getString('restaurantes');
      final restauranteSeleccionado = prefs.getString('restaurante_seleccionado');
      print('[VISTA MAPSDUE] SharedPreferences token: $token, restaurante_id: $restauranteId');
      print('[VISTA MAPSDUE] SharedPreferences restaurantes: $restaurantes');
      print('[VISTA MAPSDUE] SharedPreferences restaurante_seleccionado: $restauranteSeleccionado');
      if (token == null || token.isEmpty) {
        print('[VISTA MAPSDUE] No hay token, redirigiendo a login desde MapsDueActivity');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else if (restauranteId == null) {
        print('[VISTA MAPSDUE] No hay restaurante_id, redirigiendo a login desde MapsDueActivity');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    });
    final imageUrlBanner = getRestauranteImageUrl(_imagenRestaurante);
    print('[VISTA][D_IMAGEN] Imagen usada en banner: $imageUrlBanner');
    print('[VISTA MAPSDUE] Rebuild de MapsDueActivity. Estado actual: $_restauranteStatus');
    return PopScope(
      canPop: false, // Cambiar a false para interceptar el botón atrás
      onPopInvokedWithResult: (didPop, popAction) async {
        if (!didPop) {
          final result = await _onWillPop();
          if (result) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrlBanner.isNotEmpty
                    ? Image.network(
                  imageUrlBanner,
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
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la aplicación?'),
        content: const Text('¿Estás seguro que quieres salir de la aplicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }
}
