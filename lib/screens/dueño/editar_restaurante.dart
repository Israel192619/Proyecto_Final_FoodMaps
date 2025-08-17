import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:foodmaps/config/config.dart';
import '../publica/new_restaurante.dart' show SeleccionarUbicacionMapaScreen;

class EditarRestauranteScreen extends StatefulWidget {
  final int restauranteId;
  final Map<String, dynamic> restauranteData;

  const EditarRestauranteScreen({
    Key? key,
    required this.restauranteId,
    required this.restauranteData,
  }) : super(key: key);

  @override
  State<EditarRestauranteScreen> createState() => _EditarRestauranteScreenState();
}

class _EditarRestauranteScreenState extends State<EditarRestauranteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _imagenModificada = false;
  Uint8List? _imageBytes;
  String? _imageName;
  String? _currentImageUrl;
  final int _targetSize = 500; // Tamaño objetivo para el logo (500x500 px)

  // Controladores para los campos del formulario
  late final TextEditingController _nombreController;
  late final TextEditingController _ubicacionController;
  late final TextEditingController _celularController;
  late final TextEditingController _tematicaController;

  LatLng? _selectedLatLng;
  double? _selectedZoom;

  @override
  void initState() {
    super.initState();
    _cargarDatosRestaurante();
  }

  void _cargarDatosRestaurante() {
    final data = widget.restauranteData;

    // Inicializar controladores con datos existentes
    _nombreController = TextEditingController(text: data['nombre_restaurante'] ?? '');
    _ubicacionController = TextEditingController(text: data['ubicacion'] ?? '');
    _celularController = TextEditingController(text: data['celular']?.toString() ?? '');
    _tematicaController = TextEditingController(text: data['tematica'] ?? '');

    // Cargar imagen actual si existe
    if (data['imagen'] != null && data['imagen'].toString().isNotEmpty) {
      _currentImageUrl = AppConfig.getImageUrl(data['imagen']);
    }

    // Extraer ubicación para mapa
    final ubicacion = data['ubicacion'];
    if (ubicacion != null && ubicacion.toString().isNotEmpty) {
      final parts = ubicacion.toString().split(',');
      if (parts.length >= 2) {
        try {
          final lat = double.parse(parts[0]);
          final lng = double.parse(parts[1]);
          _selectedLatLng = LatLng(lat, lng);

          if (parts.length >= 3) {
            _selectedZoom = double.parse(parts[2]);
          }
        } catch (e) {
          print('Error al parsear coordenadas: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    _celularController.dispose();
    _tematicaController.dispose();
    super.dispose();
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
              _imagenModificada = true;
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
            _imagenModificada = true;
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

  Future<void> _actualizarRestaurante() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) {
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
      final url = AppConfig.getApiUrl(AppConfig.actualizarRestauranteEndpoint(widget.restauranteId));

      // Decidir si usar MultipartRequest (para imagen) o regular PUT request
      if (_imagenModificada && _imageBytes != null && _imageBytes!.isNotEmpty) {
        // Usar MultipartRequest para enviar la imagen
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(url),
        );

        if (token != null && token.isNotEmpty) {
          request.headers['authorization'] = 'Bearer $token';
        }

        // Añadir campos de texto
        request.fields.addAll({
          'nombre_restaurante': _nombreController.text.trim(),
          'ubicacion': _ubicacionController.text.trim(),
          'celular': _celularController.text.trim(),
          'tematica': _tematicaController.text.trim(),
          '_method': 'PUT', // Para Laravel - simular PUT con POST
        });

        // Añadir la imagen
        request.files.add(http.MultipartFile.fromBytes(
          'imagen',
          _imageBytes!,
          filename: 'logo_${DateTime.now().millisecondsSinceEpoch}.png',
        ));

        print('[VISTA EDITAR_REST] Enviando imagen con request: ${request.fields}');

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        _manejarRespuesta(response);
      } else {
        // Usar PUT regular sin imagen
        final response = await http.put(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'nombre_restaurante': _nombreController.text.trim(),
            'ubicacion': _ubicacionController.text.trim(),
            'celular': _celularController.text.trim(),
            'tematica': _tematicaController.text.trim(),
          }),
        );

        _manejarRespuesta(response);
      }
    } catch (e) {
      // Cerrar loader modal
      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      print('[VISTA EDITAR_REST] Error: $e');
      _mostrarError('Error de conexión: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _manejarRespuesta(http.Response response) async {
    // Cerrar loader modal
    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    print('[VISTA EDITAR_REST] Código de respuesta: ${response.statusCode}');
    print('[VISTA EDITAR_REST] Cuerpo de respuesta: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonResponse = jsonDecode(response.body);

        // Actualizar datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (jsonResponse['data'] != null) {
          final restaurante = jsonResponse['data'];
          await prefs.setString('restaurante_seleccionado', jsonEncode(restaurante));

          // Actualizar también en la lista de restaurantes
          final restaurantesJson = prefs.getString('restaurantes');
          if (restaurantesJson != null) {
            final restaurantes = List<Map<String, dynamic>>.from(jsonDecode(restaurantesJson));
            final index = restaurantes.indexWhere((r) => r['id'] == widget.restauranteId);
            if (index != -1) {
              restaurantes[index] = Map<String, dynamic>.from(restaurante);
              await prefs.setString('restaurantes', jsonEncode(restaurantes));
            }
          }
        }

        _mostrarExito('Restaurante actualizado correctamente');

        // Esperar un poco para que se vea el mensaje
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true); // Volver a la pantalla anterior con resultado positivo
        }
      } catch (e) {
        print('[VISTA EDITAR_REST] Error al procesar la respuesta: $e');
        _mostrarError('Error al procesar la respuesta');
      }
    } else {
      _mostrarError('Error al actualizar restaurante: ${response.statusCode}');
    }

    setState(() => _isLoading = false);
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
        title: const Text('Editar Restaurante'),
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
                                      : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Image.network(
                                                _currentImageUrl!,
                                                fit: BoxFit.cover,
                                                height: 180,
                                                width: 180,
                                                errorBuilder: (context, error, stackTrace) => Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.broken_image, size: 48, color: Colors.red.shade400),
                                                    const SizedBox(height: 10),
                                                    const Text('Error al cargar imagen'),
                                                  ],
                                                ),
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
                              if (_imagenModificada)
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
                                  icon: const Icon(Icons.save, color: Colors.white),
                                  label: const Text(
                                    'GUARDAR CAMBIOS',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () async {
                                          if (_isLoading) return;
                                          await _actualizarRestaurante();
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
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.cancel, color: Colors.grey),
                                  label: Text(
                                    'CANCELAR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : () => Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.grey.shade400, width: 2),
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
