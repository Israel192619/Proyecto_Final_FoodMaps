import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';


class NewRestauranteScreen extends StatefulWidget {
  const NewRestauranteScreen({Key? key}) : super(key: key);

  @override
  _NewRestauranteScreenState createState() => _NewRestauranteScreenState();
}

class _NewRestauranteScreenState extends State<NewRestauranteScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _userId;
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

  @override
  void initState() {
    super.initState();
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
      });
    } catch (e) {
      _mostrarError('Error al obtener ID de usuario: ${e.toString()}');
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      if (kIsWeb) {
        // Para web
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
    if (kIsWeb) return null;

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

  Future<void> _registrarRestaurante() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userId == null) {
      _mostrarError('No se pudo identificar al usuario');
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    try {
      // Crear la solicitud multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://tuapi.com/api/restaurantes'),
      );

      // Agregar campos de texto
      request.fields.addAll({
        'nombre_restaurante': _nombreController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'celular': _celularController.text.trim(),
        'estado': '0', // Siempre cerrado al registrar
        'tematica': _tematicaController.text.trim(),
        'contador_vistas': '0',
        'user_id': _userId.toString(),
      });

      // Agregar imagen si existe
      if (_imageBytes != null && _imageName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'imagen',
          _imageBytes!,
          filename: 'logo_${DateTime.now().millisecondsSinceEpoch}.png',
        ));
      }

      // Enviar la solicitud
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasRestaurant', true); // Marcar que ya tiene restaurante

        setState(() => _isSuccess = true);
        _mostrarExito('Restaurante registrado exitosamente');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/mapsDueActivity');
        }
      } else {
        throw Exception(jsonResponse['message'] ?? 'Error al registrar restaurante');
      }
    } on http.ClientException catch (e) {
      _mostrarError('Error de conexión: ${e.message}');
    } on TimeoutException {
      _mostrarError('Tiempo de espera agotado');
    } catch (e) {
      _mostrarError('Error: ${e.toString()}');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nuevo Restaurante'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección para subir logo
              GestureDetector(
                onTap: _isLoading ? null : _seleccionarImagen,
                child: Container(
                  height: 200,
                  width: 200,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      height: 200,
                      width: 200,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo, size: 50),
                      SizedBox(height: 10),
                      Text('Subir logo del restaurante'),
                      Text('(Se redimensionará a 500x500 px)',
                          style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_imageName != null)
                Text(
                  'Logo preparado: 500x500 px',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre del Restaurante',
                icon: Icons.restaurant,
                validator: (value) => value!.isEmpty ? 'Ingrese el nombre' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _ubicacionController,
                label: 'Ubicación',
                icon: Icons.location_on,
                validator: (value) => value!.isEmpty ? 'Ingrese la ubicación' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _celularController,
                label: 'Celular',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Ingrese un celular' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _tematicaController,
                label: 'Temática',
                icon: Icons.category,
                hintText: 'Ej: Comida rápida, Italiana, Vegetariana, etc.',
                validator: (value) => value!.isEmpty ? 'Ingrese la temática' : null,
              ),
              const SizedBox(height: 30),
              _buildSubmitButton(),
              const SizedBox(height: 20),
              // Botón de salir debajo del botón principal
              OutlinedButton(
                onPressed: _isLoading ? null : _salirAlLogin,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text(
                  'SALIR SIN REGISTRAR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _salirAlLogin() async {
    final prefs = await SharedPreferences.getInstance();
    // Marcar como logout forzado
    await prefs.setBool('forcedLogout', true);
    // Limpiar credenciales de sesión persistente
    await prefs.setBool('mantenersesion', false);
    await prefs.remove('username');
    await prefs.remove('password');
    await prefs.setBool('hasRestaurant', false);

    if (mounted) {
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
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _registrarRestaurante,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Text(
        'REGISTRAR RESTAURANTE',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}