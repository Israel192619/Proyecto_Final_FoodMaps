import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import '../../../config/config.dart';
import '../../../config/theme_provider.dart';
import '../../cliente/fragments/maps_page.dart'; // Importa MapsDesktopTable
import 'package:cases/constants/custom_info_window_controller.dart'; // Importa el controlador personalizado
import 'package:google_map_custom_windows/google_map_custom_windows.dart'; // <-- Agrega este import
import 'package:cases/constants/restaurant_info_window.dart'; // Reutiliza el mismo widget de info window
import '../../publica/Menu_Restaurante.dart'; // Agrega este import

class MapsDuePage extends StatefulWidget {
  final int restauranteId;

  const MapsDuePage({Key? key, required this.restauranteId}) : super(key: key);

  @override
  _MapsDuePageState createState() => _MapsDuePageState();
}

// Define la clase _MapsDuePageState como el State de MapsDuePage
class _MapsDuePageState extends State<MapsDuePage> {
  GoogleMapController? _mapController;
  CustomInfoWindowController? _customController; // Controlador para info windows personalizados
  LatLng _defaultPosition = LatLng(-17.382202, -66.151789); // Cochabamba por defecto
  Marker? _restauranteMarker;
  int _restauranteStatus = 1;

  bool? _lastIsDark;
  bool _mapStyleApplied = false;

  bool _hasCoordenadas = false;

  Set<Marker> _allMarkers = {};
  List<Map<String, dynamic>> _restaurantesData = [];
  Key _mapKey = UniqueKey(); // NUEVO: Key para forzar redibujado del mapa
  int _estadoFiltro = -1; // -1: todos, 0: cerrado, 1: abierto

  @override
  void initState() {
    super.initState();
    _customController = CustomInfoWindowController();
    _setInitialPosition();
    _fetchRestaurantData(); // Aquí se inicializa el estado correctamente
    _fetchLocationsFromApi();
  }

  Future<void> _setInitialPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final restauranteJson = prefs.getString('restaurante_seleccionado');
    if (restauranteJson != null) {
      try {
        final restaurante = jsonDecode(restauranteJson);
        if (restaurante['latitud'] != null && restaurante['longitud'] != null) {
          final lat = double.tryParse(restaurante['latitud'].toString());
          final lng = double.tryParse(restaurante['longitud'].toString());
          if (lat != null && lng != null) {
            setState(() {
              _defaultPosition = LatLng(lat, lng);
              _hasCoordenadas = true;
            });
            print('[MAPS_DUE_PAGE] Centrado en ubicación guardada: $_defaultPosition');
            return;
          }
        }
      } catch (e) {
        print('[MAPS_DUE_PAGE] Error al decodificar restaurante_seleccionado: $e');
      }
    }
    setState(() {
      _hasCoordenadas = false;
    });
    print('[MAPS_DUE_PAGE] Usando ubicación por defecto (Cochabamba)');
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
    print('[MARCADOR] _fetchRestaurantData INICIO');
    final prefs = await SharedPreferences.getInstance();
    final restauranteJson = prefs.getString('restaurante_seleccionado');
    LatLng? latLng;
    String nombre = 'Restaurante Ejemplo';
    Map<String, dynamic>? restauranteData;

    if (restauranteJson != null) {
      try {
        restauranteData = jsonDecode(restauranteJson);
        print('[MARCADOR] restauranteData obtenido: $restauranteData');
        // --- CAMBIO: Extraer lat/lng desde "ubicacion" si existe ---
        if (restauranteData != null) {
          if (restauranteData['ubicacion'] != null && restauranteData['ubicacion'] is String) {
            final ubicacionStr = restauranteData['ubicacion'] as String;
            final parts = ubicacionStr.split(',');
            if (parts.length == 2) {
              final lat = double.tryParse(parts[0]);
              final lng = double.tryParse(parts[1]);
              if (lat != null && lng != null) {
                latLng = LatLng(lat, lng);
                print('[MARCADOR] Coordenadas del restaurante (ubicacion): $latLng');
              }
            }
          } else if (restauranteData['latitud'] != null && restauranteData['longitud'] != null) {
            final lat = double.tryParse(restauranteData['latitud'].toString());
            final lng = double.tryParse(restauranteData['longitud'].toString());
            if (lat != null && lng != null) {
              latLng = LatLng(lat, lng);
              print('[MARCADOR] Coordenadas del restaurante (latitud/longitud): $latLng');
            }
          }
          if (restauranteData['nombre_restaurante'] != null) {
            nombre = restauranteData['nombre_restaurante'];
          }
          if (restauranteData['estado'] != null) {
            _restauranteStatus = restauranteData['estado'];
            print('[MARCADOR] Estado inicial del restaurante: $_restauranteStatus');
          }
        }
      } catch (e) {
        print('[MARCADOR] Error al decodificar restaurante_seleccionado en fetch: $e');
      }
    }

    setState(() {
      print('[MARCADOR] setState para crear marcador principal');
      if (latLng != null) {
        print('[MARCADOR] Creando marcador con estado $_restauranteStatus');
        _restauranteMarker = Marker(
          markerId: MarkerId(widget.restauranteId.toString()),
          position: latLng,
          // Cambia aquí para ocultar el InfoWindow nativo:
          infoWindow: InfoWindow.noText,
          icon: _restauranteStatus == 1
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            print('[window] Datos del restaurante principal al abrir ventana: $restauranteData');
            final imagenSafe = (restauranteData?['imagen'] ?? '').toString();
            print('[window] Valor seguro para imagen: $imagenSafe, tipo: ${imagenSafe.runtimeType}');
            if (restauranteData?['nombre_restaurante'] == null) print('[window] nombre_restaurante es null');
            if (restauranteData?['imagen'] == null) print('[window] imagen es null');
            if (restauranteData?['ubicacion'] == null) print('[window] ubicacion es null');
            if (restauranteData?['celular'] == null) print('[window] celular es null');
            if (restauranteData?['estado_text'] == null) print('[window] estado_text es null');
            if (_customController != null) {
              _customController!.showInfoWindow(
                [
                  RestaurantInfoWindow(
                    restaurantData: {
                      ...(restauranteData ?? {}),
                      'imagen': imagenSafe, // Siempre String, nunca null
                    },
                    onMenuPressed: () {
                      print('[window] Ver menú de restaurante: $nombre');
                    },
                  )
                ],
                [latLng!],
              );
            }
          },
        );
        print('[MARCADOR] Marcador creado: $_restauranteMarker');
      } else {
        print('[MARCADOR] No hay coordenadas, no se crea marcador');
        _restauranteMarker = null;
      }
    });
  }

  // Reemplaza _fetchAllRestaurants por la lógica de maps_page
  Future<void> _fetchLocationsFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('[MAPS_DUE_PAGE] Token obtenido de SharedPreferences: $token');
    print('[MAPS_DUE_PAGE] _fetchLocationsFromApi llamado. token=$token');
    if (token == null || token.isEmpty) {
      print('[MAPS_DUE_PAGE] No hay token de autenticación');
      setState(() {
        _restaurantesData = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No autenticado. Inicia sesión nuevamente.'))
      );
      return;
    }
    try {
      final url = '${AppConfig.apiBaseUrl}${AppConfig.restaurantesClienteEndpoint}';
      print('[WSO][RUTA] GET restaurantes cliente: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[MAPS_DUE_PAGE] Headers enviados: Authorization: Bearer $token');
      print('[MAPS_DUE_PAGE] Respuesta statusCode: ${response.statusCode}');
      print('[MAPS_DUE_PAGE] Respuesta body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ADAPTACIÓN: Usa la clave 'data' que contiene la lista de restaurantes
        List<Map<String, dynamic>> restaurantesDataTmp = [];
        if (data is Map && data.containsKey('data') && data['data'] is List) {
          restaurantesDataTmp = List<Map<String, dynamic>>.from(data['data']);
        } else {
          restaurantesDataTmp = [];
        }

        print('[MAPS_DUE_PAGE] Restaurantes extraídos: $restaurantesDataTmp');
        Set<Marker> markers = {};
        for (var obj in restaurantesDataTmp) {
          print('[MAPS_DUE_PAGE] Procesando restaurante: $obj');
          final latLngStr = obj['ubicacion']?.toString();
          double? lat, lng;
          if (latLngStr != null && latLngStr.contains(',')) {
            final parts = latLngStr.split(',');
            lat = double.tryParse(parts[0]);
            lng = double.tryParse(parts[1]);
          }
          final estado = obj['estado'] is int ? obj['estado'] : int.tryParse(obj['estado'].toString()) ?? 1;
          if (lat == null || lng == null) {
            print('[MAPS_DUE_PAGE] Restaurante sin coordenadas, solo tabla.');
            continue;
          }
          final markerId = MarkerId(obj['id'].toString());
          final icon = BitmapDescriptor.defaultMarkerWithHue(
            estado == 0 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
          );
          final position = LatLng(lat, lng);
          markers.add(
            Marker(
              markerId: markerId,
              position: position,
              // Cambia aquí para ocultar el InfoWindow nativo:
              infoWindow: InfoWindow.noText,
              icon: icon,
              onTap: () {
                print('[window] Datos del restaurante al abrir ventana: $obj');
                final imagenSafe = (obj['imagen'] ?? '').toString();
                print('[window] Valor seguro para imagen: $imagenSafe, tipo: ${imagenSafe.runtimeType}');
                if (obj['nombre_restaurante'] == null) print('[window] nombre_restaurante es null');
                if (obj['imagen'] == null) print('[window] imagen es null');
                if (obj['ubicacion'] == null) print('[window] ubicacion es null');
                if (obj['celular'] == null) print('[window] celular es null');
                if (obj['estado_text'] == null) print('[window] estado_text es null');
                final infoWidget = RestaurantInfoWindow(
                  restaurantData: {
                    ...obj,
                    'imagen': imagenSafe, // Siempre String, nunca null
                  },
                  onMenuPressed: () {
                    // Navega a Menu_Restaurante.dart
                    final int restaurantId = obj['restaurante_id'] is int
                        ? obj['restaurante_id']
                        : (obj['id'] is int
                            ? obj['id']
                            : int.tryParse(obj['restaurante_id']?.toString() ?? obj['id']?.toString() ?? '0') ?? 0);
                    final String name = obj['nom_rest'] ?? obj['nombre_restaurante'] ?? '';
                    final String phone = obj['celular']?.toString() ?? '';
                    final String imageUrl = obj['imagen']?.toString() ?? '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MenuRestaurante(
                          restaurantId: restaurantId,
                          name: name,
                          phone: phone,
                          imageUrl: imageUrl,
                        ),
                      ),
                    );
                  },
                );
                _customController?.showInfoWindow([infoWidget], [position]);
              },
            ),
          );
        }
        print('[MAPS_DUE_PAGE] Total restaurantes agregados a _restaurantesData: ${restaurantesDataTmp.length}');
        setState(() {
          _allMarkers = markers;
          _restaurantesData = restaurantesDataTmp;
        });
      } else if (response.statusCode == 401) {
        print('[MAPS_DUE_PAGE] Error de autenticación: ${response.body}');
        setState(() {
          _restaurantesData = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No autenticado. Por favor, inicia sesión nuevamente.'))
        );
      } else {
        print('[MAPS_DUE_PAGE] Error al obtener restaurantes: ${response.statusCode}');
        setState(() {
          _restaurantesData = [];
        });
      }
    } catch (e) {
      print('[MAPS_DUE_PAGE] Excepción al obtener restaurantes: $e');
      setState(() {
        _restaurantesData = [];
      });
    }
  }

  // Metodo público para actualizar el estado y el marcador desde fuera
  void actualizarEstadoRestaurante(int nuevoEstado) {
    print('[MARCADOR] actualizarEstadoRestaurante llamado con estado: $nuevoEstado');
    setState(() {
      print('[MARCADOR] setState dentro de actualizarEstadoRestaurante');
      _restauranteStatus = nuevoEstado;
      if (_restauranteMarker != null) {
        print('[MARCADOR] Eliminando marcador anterior');
        _restauranteMarker = null;
      }
      // Vuelve a crear el marcador principal con el nuevo color
      final prefs = SharedPreferences.getInstance();
      prefs.then((sprefs) {
        final restauranteJson = sprefs.getString('restaurante_seleccionado');
        if (restauranteJson != null) {
          try {
            final restauranteData = jsonDecode(restauranteJson);
            LatLng? latLng;
            String nombre = restauranteData['nombre_restaurante'] ?? 'Restaurante';
            if (restauranteData['ubicacion'] != null && restauranteData['ubicacion'] is String) {
              final ubicacionStr = restauranteData['ubicacion'] as String;
              final parts = ubicacionStr.split(',');
              if (parts.length == 2) {
                final lat = double.tryParse(parts[0]);
                final lng = double.tryParse(parts[1]);
                if (lat != null && lng != null) {
                  latLng = LatLng(lat, lng);
                }
              }
            }
            if (latLng != null) {
              print('[MARCADOR] Creando nuevo marcador con estado $nuevoEstado');
              setState(() {
                _restauranteMarker = Marker(
                  markerId: MarkerId(widget.restauranteId.toString()),
                  position: latLng!,
                  infoWindow: InfoWindow(title: nombre),
                  icon: nuevoEstado == 1
                      ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                      : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                );
              });
            } else {
              print('[MARCADOR] No se pudo obtener coordenadas para el nuevo marcador');
            }
          } catch (e) {
            print('[MARCADOR] Error al crear nuevo marcador: $e');
          }
        }
      });
    });
  }

  // NUEVO: Actualiza el marcador de cualquier restaurante por su ID y estado
  void actualizarMarcadorRestaurantePorId(int id, int nuevoEstado) {
    print('[MARCADOR] actualizarMarcadorRestaurantePorId llamado para id=$id, estado=$nuevoEstado');
    Marker? marcadorAnterior;
    try {
      marcadorAnterior = _allMarkers.firstWhere(
        (m) => m.markerId.value == id.toString(),
      );
    } catch (e) {
      marcadorAnterior = null;
    }
    setState(() {
      if (marcadorAnterior != null) {
        print('[MARCADOR] Eliminando marcador anterior de id=$id');
        _allMarkers.remove(marcadorAnterior);
        final nuevaPos = marcadorAnterior.position;
        final nuevoNombre = marcadorAnterior.infoWindow.title ?? '';
        final nuevoIcono = nuevoEstado == 1
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        final nuevoMarcador = Marker(
          markerId: MarkerId(id.toString()),
          position: nuevaPos,
          infoWindow: InfoWindow(title: nuevoNombre),
          icon: nuevoIcono,
        );
        _allMarkers.add(nuevoMarcador);
        print('[MARCADOR] Marcador actualizado en _allMarkers para id=$id');
        // Elimina la línea que fuerza el redibujado de todoo el mapa:
        // _mapKey = UniqueKey();
      } else {
        print('[MARCADOR] No se encontró marcador para id=$id');
      }
    });
  }

  // Widget _buildCustomInfoWindow() {
  //   // Ya no se usa, ahora se reutiliza RestaurantInfoWindow
  //   return const SizedBox.shrink();
  // }

  @override
  Widget build(BuildContext context) {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    print('[MARCADOR] build() llamado');
    print('[MAPS_DUE_PAGE] Plataforma detectada: ${defaultTargetPlatform.toString()}, isDesktop=$isDesktop, kIsWeb=$kIsWeb');
    print('[MAPS_DUE_PAGE] _restaurantesData.length=${_restaurantesData.length}');

    if (isDesktop) {
      print('[MAPS_DUE_PAGE] Mostrando tabla de restaurantes en escritorio');
      return _buildDesktopTable(context);
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        if (_mapController != null &&
            (_lastIsDark != themeProvider.isDarkMode || !_mapStyleApplied)) {
          print('[MAP_STYLE] build() detecta cambio de tema o estilo no aplicado');
          _applyMapStyle(themeProvider.isDarkMode);
        }
        _lastIsDark = themeProvider.isDarkMode;

        Set<Marker> markersToShow = {..._allMarkers};
        if (_restauranteMarker != null) {
          print('[MARCADOR] Agregando marcador principal al mapa');
          markersToShow.add(_restauranteMarker!);
        } else {
          print('[MARCADOR] No hay marcador principal para agregar');
        }
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 10,
                          children: [
                            ChoiceChip(
                              label: Row(
                                children: const [
                                  Icon(Icons.all_inclusive, size: 18),
                                  SizedBox(width: 6),
                                  Text('Todos'),
                                ],
                              ),
                              selected: _estadoFiltro == -1,
                              selectedColor: Colors.red.shade400,
                              backgroundColor: Colors.red.shade100,
                              labelStyle: TextStyle(
                                color: _estadoFiltro == -1 ? Colors.white : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              elevation: _estadoFiltro == -1 ? 6 : 2,
                              onSelected: (selected) {
                                setState(() {
                                  _estadoFiltro = -1;
                                  _actualizarMarcadores();
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  SizedBox(width: 6),
                                  Text('Abiertos'),
                                ],
                              ),
                              selected: _estadoFiltro == 1,
                              selectedColor: Colors.green.shade400,
                              backgroundColor: Colors.green.shade100,
                              labelStyle: TextStyle(
                                color: _estadoFiltro == 1 ? Colors.white : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              elevation: _estadoFiltro == 1 ? 6 : 2,
                              onSelected: (selected) {
                                setState(() {
                                  _estadoFiltro = 1;
                                  _actualizarMarcadores();
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Row(
                                children: const [
                                  Icon(Icons.cancel, color: Colors.red, size: 18),
                                  SizedBox(width: 6),
                                  Text('Cerrados'),
                                ],
                              ),
                              selected: _estadoFiltro == 0,
                              selectedColor: Colors.red.shade400,
                              backgroundColor: Colors.red.shade100,
                              labelStyle: TextStyle(
                                color: _estadoFiltro == 0 ? Colors.white : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                              elevation: _estadoFiltro == 0 ? 6 : 2,
                              onSelected: (selected) {
                                setState(() {
                                  _estadoFiltro = 0;
                                  _actualizarMarcadores();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      key: _mapKey,
                      onMapCreated: (controller) async {
                        print('[MAP_STYLE] onMapCreated llamado');
                        _mapController = controller;
                        _mapStyleApplied = false;
                        await _applyMapStyle(themeProvider.isDarkMode);
                        if (_customController != null) {
                          _customController!.initialize(controller);
                        }
                        _mapController?.moveCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: _defaultPosition, zoom: 15),
                          ),
                        );
                      },
                      initialCameraPosition: CameraPosition(target: _defaultPosition, zoom: 15),
                      markers: markersToShow,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      onTap: (_) => _customController?.hideInfoWindow(),
                      onCameraMove: (_) => _customController?.customController.onCameraMove!(),
                    ),
                    if (_customController != null)
                      CustomMapInfoWindow(
                        controller: _customController!.customController,
                        offset: const Offset(0, 30),
                        height: 170,
                        width: 180,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _actualizarMarcadores() {
    Set<Marker> filteredMarkers = {};
    for (var obj in _restaurantesData) {
      final estado = obj['estado'] is int ? obj['estado'] : int.tryParse(obj['estado'].toString()) ?? 1;
      if (_estadoFiltro != -1 && estado != _estadoFiltro) continue;

      final latLngStr = obj['ubicacion']?.toString();
      double? lat, lng;
      if (latLngStr != null && latLngStr.contains(',')) {
        final parts = latLngStr.split(',');
        lat = double.tryParse(parts[0]);
        lng = double.tryParse(parts[1]);
      }
      if (lat == null || lng == null) {
        print('[MAPS_DUE_PAGE] Restaurante sin coordenadas, solo tabla.');
        continue;
      }

      final markerId = MarkerId(obj['id'].toString());
      final icon = estado == 1
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

      final position = LatLng(lat, lng);
      filteredMarkers.add(
        Marker(
          markerId: markerId,
          position: position,
          icon: icon,
          onTap: () {
            final imagenSafe = (obj['imagen'] ?? '').toString();
            final infoWidget = RestaurantInfoWindow(
              restaurantData: {
                ...obj,
                'imagen': imagenSafe,
              },
              onMenuPressed: () {
                final int restaurantId = obj['restaurante_id'] is int
                    ? obj['restaurante_id']
                    : (obj['id'] is int
                        ? obj['id']
                        : int.tryParse(obj['restaurante_id']?.toString() ?? obj['id']?.toString() ?? '0') ?? 0);
                final String name = obj['nom_rest'] ?? obj['nombre_restaurante'] ?? '';
                final String phone = obj['celular']?.toString() ?? '';
                final String imageUrl = obj['imagen']?.toString() ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuRestaurante(
                      restaurantId: restaurantId,
                      name: name,
                      phone: phone,
                      imageUrl: imageUrl,
                    ),
                  ),
                );
              },
            );
            _customController?.showInfoWindow([infoWidget], [position]);
          },
        ),
      );
    }
    setState(() {
      _allMarkers = filteredMarkers;
    });
  }

  Widget _buildDesktopTable(BuildContext context) {
    // Reutiliza el widget de tabla de escritorio de maps_page
    return MapsDesktopTable(
      restaurantesData: _restaurantesData,
      onMenuPressed: (rest) {
        // Navega a Menu_Restaurante.dart
        final int restaurantId = rest['restaurante_id'] is int
            ? rest['restaurante_id']
            : (rest['id'] is int
                ? rest['id']
                : int.tryParse(rest['restaurante_id']?.toString() ?? rest['id']?.toString() ?? '0') ?? 0);
        final String name = rest['nom_rest'] ?? rest['nombre_restaurante'] ?? '';
        final String phone = rest['celular']?.toString() ?? '';
        final String imageUrl = rest['imagen']?.toString() ?? '';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuRestaurante(
              restaurantId: restaurantId,
              name: name,
              phone: phone,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
    );
  }
}

