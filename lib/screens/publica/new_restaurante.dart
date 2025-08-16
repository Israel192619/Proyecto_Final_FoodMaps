import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cases/config/config.dart';
import 'package:provider/provider.dart';
import 'package:cases/config/theme_provider.dart';


class NewRestauranteScreen extends StatefulWidget {
  const NewRestauranteScreen({Key? key}) : super(key: key);

  @override
  _NewRestauranteScreenState createState() => _NewRestauranteScreenState();
}

class _NewRestauranteScreenState extends State<NewRestauranteScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _userId;
  int? _userRole; // Agregar para almacenar el rol del usuario
  bool _isLoading = false;
  bool _isSuccess = false;
  Uint8List? _imageBytes;
  String? _imageName;
  final int _targetSize = 500; // Tamaño objetivo para el logo (500x500 px)

  // Controladores para los campos del formulario
  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _celularController = TextEditingController();
  final _tematicaController = TextEditingController();

  LatLng? _selectedLatLng;
  String? _selectedAddress;
  double? _selectedZoom;

  @override
  void initState() {
    super.initState();
    print('[VISTA NEWREST] INITSTATE');
    _obtenerUserId();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    _celularController.dispose();
    _tematicaController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getInt('user_id');
        _userRole = prefs.getInt('userRole'); // Obtener también el rol
      });
      print('[VISTA NEWREST] Usuario ID: $_userId, Rol: $_userRole');
    } catch (e) {
      _mostrarError('Error al obtener ID de usuario: ${e.toString()}');
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      // Solo permite seleccionar desde archivos en web y escritorio
      if (kIsWeb || (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
                                 defaultTargetPlatform == TargetPlatform.linux ||
                                 defaultTargetPlatform == TargetPlatform.macOS))) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          final bytes = file.bytes;
          if (bytes != null) {
            final resizedImage = await _resizeImage(bytes);
            setState(() {
              _imageBytes = resizedImage;
              _imageName = file.name;
            });
          }
        }
      } else {
        // Para móvil
        final picker = ImagePicker();
        final source = await _mostrarSelectorFuenteImagen();
        if (source == null) return;
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          final resizedImage = await _resizeImage(bytes);
          setState(() {
            _imageBytes = resizedImage;
            _imageName = pickedFile.name;
          });
        }
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  Future<Uint8List> _resizeImage(Uint8List bytes) async {
    // Decodificar la imagen original
    final codec = await ui.instantiateImageCodec(bytes);
    final originalImage = (await codec.getNextFrame()).image;

    // Calcular dimensiones para recorte cuadrado
    final int originalWidth = originalImage.width;
    final int originalHeight = originalImage.height;
    final int cropSize = min(originalWidth, originalHeight);

    // Calcular punto de inicio para recorte centrado
    final int offsetX = (originalWidth - cropSize) ~/ 2;
    final int offsetY = (originalHeight - cropSize) ~/ 2;

    // Recortar y redimensionar
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Dibujar la imagen recortada y redimensionada
    final paint = Paint();
    final srcRect = Rect.fromLTWH(
        offsetX.toDouble(),
        offsetY.toDouble(),
        cropSize.toDouble(),
        cropSize.toDouble()
    );
    final dstRect = Rect.fromLTWH(0, 0, _targetSize.toDouble(), _targetSize.toDouble());

    canvas.drawImageRect(originalImage, srcRect, dstRect, paint);
    originalImage.dispose();

    // Convertir a formato PNG
    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(_targetSize, _targetSize);
    final byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    resizedImage.dispose();

    return byteData!.buffer.asUint8List();
  }

  Future<ImageSource?> _mostrarSelectorFuenteImagen() async {
    // Solo para móvil, no para web/escritorio
    if (kIsWeb || (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows ||
                               defaultTargetPlatform == TargetPlatform.linux ||
                               defaultTargetPlatform == TargetPlatform.macOS))) {
      return null;
    }
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen desde'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Cámara'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Galería'),
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarUbicacionEnMapa() async {
    LatLng initialPosition = _selectedLatLng ?? LatLng(-17.382202, -66.151789); // Cochabamba por defecto
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarUbicacionMapaScreen(
          initialPosition: initialPosition,
          initialZoom: _selectedZoom ?? 18,
        ),
      ),
    );
    if (result != null && result is Map) {
      setState(() {
        _selectedLatLng = result['latlng'];
        _selectedZoom = result['zoom'];
      });
      // Mostrar coordenadas exactas en el campo
      final coordsStr = '${_selectedLatLng!.latitude},${_selectedLatLng!.longitude},${_selectedZoom?.toStringAsFixed(2) ?? "18"}';
      setState(() {
        _ubicacionController.text = coordsStr;
      });
    }
  }

  Future<void> _registrarRestaurante() async {
    print('[VISTA NEWREST] INICIO _registrarRestaurante');
    if (_isLoading) return; // Evita doble pulsación
    if (!_formKey.currentState!.validate()) {
      print('[VISTA NEWREST] Formulario no válido');
      return;
    }
    if (_userId == null) {
      print('[VISTA NEWREST] No se pudo identificar al usuario');
      _mostrarError('No se pudo identificar al usuario');
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    // Mostrar loader modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // --- NUEVO: Actualizar rol del usuario a "Dueño" antes de registrar restaurante ---
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final actualizarUsuarioUrl = AppConfig.getApiUrl(AppConfig.actualizarUsuarioEndpoint(_userId!));
      print('[VISTA NEWREST] Actualizando rol usuario: $actualizarUsuarioUrl');
      final putResponse = await http.put(
        Uri.parse(actualizarUsuarioUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rol': 'Dueño'}),
      );
      print('[VISTA NEWREST] PUT usuario statusCode: ${putResponse.statusCode}');
      print('[VISTA NEWREST] PUT usuario body: ${putResponse.body}');
      if (putResponse.statusCode != 200) {
        Navigator.of(context, rootNavigator: true).pop();
        _mostrarError('No se pudo actualizar el rol del usuario. Intente nuevamente.');
        setState(() => _isLoading = false);
        return;
      }

      // Crear la solicitud multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.getRegistrarRestauranteUrl()),
      );

      // --- CORREGIDO: El header debe ser 'authorization' en minúsculas ---
      if (token != null && token.isNotEmpty) {
        request.headers['authorization'] = 'Bearer $token';
      }
      // Elimina el header 'Content-Type' aquí, lo maneja MultipartRequest automáticamente

      // Agregar campos de texto
      request.fields.addAll({
        'nombre_restaurante': _nombreController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'celular': _celularController.text.trim(),
        'estado': '0',
        'tematica': _tematicaController.text.trim(),
        'contador_vistas': '0',
        'user_id': _userId.toString(),
        if (_selectedLatLng != null) 'latitud': _selectedLatLng!.latitude.toString(),
        if (_selectedLatLng != null) 'longitud': _selectedLatLng!.longitude.toString(),
        if (_selectedZoom != null) 'zoom': _selectedZoom!.toString(),
      });

      // Agregar imagen si existe
      if (_imageBytes != null && _imageName != null && _imageBytes!.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'imagen',
          _imageBytes!,
          filename: 'logo_${DateTime.now().millisecondsSinceEpoch}.png',
        ));
      }

      print('[VISTA NEWREST] Campos enviados: ${request.fields}');
      print('[VISTA NEWREST] Headers enviados: ${request.headers}');
      print('[VISTA NEWREST] URL: ${AppConfig.getRegistrarRestauranteUrl()}');
      print('[VISTA NEWREST] Tiene imagen: ${_imageBytes != null && _imageBytes!.isNotEmpty}');

      // Enviar la solicitud
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('[VISTA NEWREST] statusCode: ${response.statusCode}');
      print('[VISTA NEWREST] responseData: $responseData');
      print('[VISTA NEWREST] Content-Type recibido: ${response.headers['content-type']}');

      if (response.statusCode == 201) {
        try {
          final jsonResponse = jsonDecode(responseData);
          print('[VISTA NEWREST] Restaurante creado exitosamente: $jsonResponse');
          final prefs = await SharedPreferences.getInstance();
          final restaurante = jsonResponse['data'];
          final restauranteId = restaurante?['id'];

          // Guarda los datos igual que en login
          if (restauranteId != null) {
            await prefs.setInt('restaurante_id', restauranteId);
            await prefs.setString('restaurante_seleccionado', jsonEncode(restaurante));
            await prefs.setBool('hasRestaurant', true);
            await prefs.setBool('forcedLogout', false);
            print('[VISTA NEWREST] Restaurante guardado en SharedPreferences');
          }

          // --- LOGIN AUTOMÁTICO ANTES DE REDIRIGIR AL AUTHWRAPPER ---
          final username = prefs.getString('username');
          final password = prefs.getString('password');
          if (username != null && password != null) {
            print('[VISTA NEWREST] Login automático después de registrar restaurante');
            final apiUrl = AppConfig.getApiUrl(AppConfig.loginEndpoint);
            final loginResponse = await http.post(
              Uri.parse(apiUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'username': username,
                'password': password,
              }),
            );
            print('[VISTA NEWREST] Respuesta login statusCode: ${loginResponse.statusCode}');
            print('[VISTA NEWREST] Respuesta login body: ${loginResponse.body}');
            if (loginResponse.statusCode == 200 || loginResponse.statusCode == 201 || loginResponse.statusCode == 202) {
              final loginData = jsonDecode(loginResponse.body);
              final token = loginData['access_token'];
              final user = loginData['user'];
              final roleId = user['role_id'];
              final userId = user['id'];
              await prefs.setString('auth_token', token);
              await prefs.setInt('userRole', roleId);
              await prefs.setInt('user_id', userId);
              await prefs.setBool('forcedLogout', false);
              print('[VISTA NEWREST] Login automático exitoso después de registrar restaurante');

              // --- ACTUALIZA LA LISTA DE RESTAURANTES ---
              var restaurantes = loginData['restaurantes'] ?? loginData['restaurante'];
              List<dynamic> restaurantesList = [];
              if (restaurantes is List) {
                restaurantesList = restaurantes;
              } else if (restaurantes is Map) {
                restaurantesList = [restaurantes];
              }
              // Si el restaurante recién creado no está en la lista, lo agregamos
              if (restauranteId != null && restaurantesList.every((r) => r['id'] != restauranteId)) {
                restaurantesList.add(restaurante);
              }
              await prefs.setString('restaurantes', jsonEncode(restaurantesList));
              print('[VISTA NEWREST] Restaurantes actualizados en SharedPreferences: $restaurantesList');
            } else {
              print('[VISTA NEWREST] Error en login automático después de registrar restaurante');
            }
          } else {
            print('[VISTA NEWREST] No hay credenciales para login automático después de registrar restaurante');
          }

          setState(() => _isSuccess = true);
          _mostrarExito('Restaurante registrado exitosamente');
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            // --- PRINT DETALLADO DE SHARED PREFERENCES ---
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            final username = prefs.getString('username');
            final password = prefs.getString('password');
            final userRole = prefs.getInt('userRole');
            final userId = prefs.getInt('user_id');
            final forcedLogout = prefs.getBool('forcedLogout');
            final restauranteId = prefs.getInt('restaurante_id');
            final restaurantes = prefs.getString('restaurantes');
            final restauranteSeleccionado = prefs.getString('restaurante_seleccionado');
            final hasRestaurant = prefs.getBool('hasRestaurant');
            print('========== [VISTA NEWREST] [DEBUG SHARED PREFERENCES DESPUÉS DE REGISTRO RESTAURANTE] ==========');
            print('auth_token: $token');
            print('username: $username');
            print('password: $password');
            print('userRole: $userRole');
            print('user_id: $userId');
            print('forcedLogout: $forcedLogout');
            print('restaurante_id: $restauranteId');
            print('restaurantes: $restaurantes');
            print('restaurante_seleccionado: $restauranteSeleccionado');
            print('hasRestaurant: $hasRestaurant');
            print('=======================================================================');

            print('[VISTA NEWREST] [REDIR] Redirigiendo a AuthWrapper (/) después de registrar restaurante');
            // Cierra el loader modal antes de redirigir
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          }
        } catch (e) {
          print('[VISTA NEWREST] Error al decodificar respuesta: $e');
          _mostrarError('Error al procesar respuesta del servidor');
        }
      } else {
        print('[VISTA NEWREST] ERROR AL REGISTRAR: statusCode=${response.statusCode}');
        print('[VISTA NEWREST] Campos enviados en error: ${request.fields}');
        print('[VISTA NEWREST] Headers enviados en error: ${request.headers}');
        _mostrarError('Error al registrar restaurante: ${response.statusCode}\n${responseData}');
      }
    } on http.ClientException catch (e) {
      print('[VISTA NEWREST] Error de conexión: ${e.message}');
      _mostrarError('Error de conexión: ${e.message}');
    } on TimeoutException {
      print('[VISTA NEWREST] Tiempo de espera agotado');
      _mostrarError('Tiempo de espera agotado');
    } catch (e) {
      print('[VISTA NEWREST] ErrorFORM: ${e.toString()}');
      _mostrarError('ErrorFORM: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // Elimina el pop aquí para evitar doble cierre del loader modal
        // Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _continuarComoCliente() async {
    if (_isLoading) return;
    if (_userId == null) {
      _mostrarError('No se pudo identificar al usuario');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Mostrar loader modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final actualizarUsuarioUrl = AppConfig.getApiUrl(AppConfig.actualizarUsuarioEndpoint(_userId!));
      print('[VISTA NEWREST] Actualizando rol usuario a Cliente: $actualizarUsuarioUrl');

      final putResponse = await http.put(
        Uri.parse(actualizarUsuarioUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rol': 'Cliente'}),
      );

      print('[VISTA NEWREST] PUT usuario statusCode: ${putResponse.statusCode}');
      print('[VISTA NEWREST] PUT usuario body: ${putResponse.body}');

      // Cerrar loader modal
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (putResponse.statusCode == 200) {
        // Actualizar el rol en SharedPreferences
        await prefs.setInt('userRole', 1); // 1 = Cliente

        _mostrarExito('Rol actualizado a Cliente exitosamente');
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          print('[VISTA NEWREST] [REDIR] Redirigiendo a AuthWrapper (/) después de actualizar rol');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }
      } else {
        _mostrarError('No se pudo actualizar el rol del usuario. Intente nuevamente.');
      }
    } catch (e) {
      // Cerrar loader modal
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      print('[VISTA NEWREST] Error al actualizar rol: $e');
      _mostrarError('Error de conexión al actualizar rol');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    final formMaxWidth = isWide ? 520.0 : screenWidth * 0.98;
    final horizontalPadding = isWide ? 32.0 : 8.0;
    final verticalPadding = isWide ? 40.0 : 16.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    // Detecta si es escritorio
    final isDesktop = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.linux ||
       defaultTargetPlatform == TargetPlatform.macOS);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nuevo Restaurante'),
        centerTitle: true,
        backgroundColor: isDark ? Colors.black : Colors.red.shade700,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: formMaxWidth,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      color: isDark ? Colors.grey[900] : Colors.white,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isWide ? 40 : 24,
                          horizontal: isWide ? 32 : 16,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Datos del Restaurante',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.red.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Divider(thickness: 1.5, color: isDark ? Colors.red.shade900 : Colors.red.shade100),
                              const SizedBox(height: 18),
                              GestureDetector(
                                onTap: _isLoading ? null : _seleccionarImagen,
                                child: Container(
                                  height: 180,
                                  width: 180,
                                  margin: const EdgeInsets.symmetric(vertical: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.red.shade900 : Colors.red.shade200,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black54 : Colors.red.shade50,
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _imageBytes != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.memory(
                                            _imageBytes!,
                                            fit: BoxFit.cover,
                                            height: 180,
                                            width: 180,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo, size: 48, color: Colors.red.shade400),
                                            const SizedBox(height: 10),
                                            Text(
                                              kIsWeb || isDesktop
                                                ? 'Selecciona una imagen desde el explorador de archivos'
                                                : 'Subir logo del restaurante',
                                              style: TextStyle(color: isDark ? Colors.white : Colors.red.shade700),
                                            ),
                                            const Text('(Se redimensionará a 500x500 px)',
                                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          ],
                                        ),
                                ),
                              ),
                              if (_imageName != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Logo preparado: 500x500 px',
                                    style: const TextStyle(fontSize: 12, color: Colors.green),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const SizedBox(height: 24),
                              _buildTextField(
                                controller: _nombreController,
                                label: 'Nombre del Restaurante',
                                icon: Icons.restaurant,
                                validator: (value) => value!.isEmpty ? 'Ingrese el nombre' : null,
                                isDark: isDark,
                                textColor: textColor,
                              ),
                              const SizedBox(height: 18),
                              // CAMBIO: Campo de ubicación según plataforma
                              if (kIsWeb || isDesktop)
                                _buildTextField(
                                  controller: _ubicacionController,
                                  label: 'Ubicación (coordenadas o dirección)',
                                  icon: Icons.location_on,
                                  hintText: 'Ej: -17.38,-66.15 o dirección textual',
                                  validator: (value) => value!.isEmpty ? 'Ingrese la ubicación' : null,
                                  isDark: isDark,
                                  textColor: textColor,
                                )
                              else
                                GestureDetector(
                                  onTap: _isLoading ? null : _seleccionarUbicacionEnMapa,
                                  child: AbsorbPointer(
                                    child: _buildTextField(
                                      controller: _ubicacionController,
                                      label: 'Ubicación',
                                      icon: Icons.location_on,
                                      validator: (value) => value!.isEmpty ? 'Seleccione la ubicación' : null,
                                      isDark: isDark,
                                      textColor: textColor,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _celularController,
                                label: 'Celular',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) => value!.isEmpty ? 'Ingrese un celular' : null,
                                isDark: isDark,
                                textColor: textColor,
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _tematicaController,
                                label: 'Temática',
                                icon: Icons.category,
                                hintText: 'Ej: Comida rápida, Italiana, Vegetariana, etc.',
                                validator: (value) => value!.isEmpty ? 'Ingrese la temática' : null,
                                isDark: isDark,
                                textColor: textColor,
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle, color: Colors.white),
                                  label: const Text(
                                    'REGISTRAR RESTAURANTE',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          if (_isLoading) return;
                                          await _registrarRestaurante();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 8,
                                  ),
                                ),
                              ),
                              // Mostrar botón "Continuar como Cliente" solo si el rol es 2 (Dueño)
                              if (_userRole == 2) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.person, color: Colors.white),
                                    label: const Text(
                                      'CONTINUAR COMO CLIENTE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _continuarComoCliente,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                                  label: Text(
                                    'SALIR SIN REGISTRAR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _salirAlLogin,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.red.shade700, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _salirAlLogin() async {
    // Mostrar loader modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final prefs = await SharedPreferences.getInstance();
    // Guarda el modo oscuro antes de limpiar
    final mapTheme = prefs.getString('map_theme');
    // Marcar como logout forzado
    await prefs.setBool('forcedLogout', true);
    // Limpiar credenciales de sesión persistente
    await prefs.setBool('mantenersesion', false);
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.setBool('hasRestaurant', false);
    await prefs.remove('restaurante_id');
    await prefs.remove('restaurantes');
    // Restaurar el modo oscuro después de limpiar
    if (mapTheme != null) {
      await prefs.setString('map_theme', mapTheme);
      // Fuerza el tema oscuro si el valor es 'oscuro'
      if (mapTheme == 'oscuro') {
        Provider.of<ThemeProvider>(context, listen: false).setDarkMode(true);
      } else {
        Provider.of<ThemeProvider>(context, listen: false).setDarkMode(false);
      }
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      print('[VISTA NEWREST] [REDIR] Redirigiendo a LoginScreen desde botón salir');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
    bool isDark = false,
    Color textColor = Colors.black,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: textColor),
        hintText: hintText,
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
        labelStyle: TextStyle(color: textColor),
      ),
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 18, color: textColor),
      validator: validator,
    );
  }
}

// --- Widget para seleccionar ubicación en el mapa ---
class SeleccionarUbicacionMapaScreen extends StatefulWidget {
  final LatLng initialPosition;
  final double initialZoom;
  const SeleccionarUbicacionMapaScreen({required this.initialPosition, required this.initialZoom});

  @override
  State<SeleccionarUbicacionMapaScreen> createState() => _SeleccionarUbicacionMapaScreenState();
}

class _SeleccionarUbicacionMapaScreenState extends State<SeleccionarUbicacionMapaScreen> {
  LatLng? _pickedLatLng;
  double _zoom = 18;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _pickedLatLng = widget.initialPosition;
    _zoom = widget.initialZoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar ubicación')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: widget.initialZoom,
            ),
            onMapCreated: (controller) {
              _controller = controller;
            },
            markers: _pickedLatLng != null
                ? {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _pickedLatLng!,
                      draggable: true,
                      onDragEnd: (pos) {
                        setState(() {
                          _pickedLatLng = pos;
                        });
                      },
                    ),
                  }
                : {},
            onTap: (latLng) {
              setState(() {
                _pickedLatLng = latLng;
              });
            },
            onCameraMove: (position) {
              _zoom = position.zoom;
            },
          ),
          // Instrucciones arriba del mapa
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withOpacity(0.95),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toca el mapa o arrastra el marcador para establecer la ubicación exacta de tu restaurante.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botón "Seleccionar" centrado abajo, separado de los controles de zoom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 180,
                child: ElevatedButton.icon(
                  onPressed: _pickedLatLng != null
                      ? () => Navigator.pop(context, {
                            'latlng': _pickedLatLng,
                            'zoom': _zoom,
                          })
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text('Seleccionar ubicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
