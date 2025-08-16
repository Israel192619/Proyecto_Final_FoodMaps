import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AgregarProductoPage extends StatefulWidget {
  final int restauranteId;
  final int tipoProducto; // 0: plato, 1: bebida

  const AgregarProductoPage({
    Key? key,
    required this.restauranteId,
    required this.tipoProducto,
  }) : super(key: key);

  @override
  State<AgregarProductoPage> createState() => _AgregarProductoPageState();
}

class _AgregarProductoPageState extends State<AgregarProductoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imagePath;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController.addListener(_refreshPreview);
    _precioController.addListener(_refreshPreview);
    _descripcionController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _nombreController.removeListener(_refreshPreview);
    _precioController.removeListener(_refreshPreview);
    _descripcionController.removeListener(_refreshPreview);
    _nombreController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    setState(() {});
  }

  Future<void> _seleccionarImagen() async {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
         defaultTargetPlatform == TargetPlatform.linux ||
         defaultTargetPlatform == TargetPlatform.macOS);

    final picker = ImagePicker();

    if (kIsWeb) {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imagePath = picked.name;
        });
      }
    } else if (isDesktop) {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imagePath = picked.path;
        });
      }
    } else {
      // Móvil: mostrar diálogo para elegir cámara o galería
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar imagen'),
          content: const Text('¿De dónde desea obtener la imagen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Cámara'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Galería'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
      if (source != null) {
        final picked = await picker.pickImage(source: source);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _imageBytes = bytes;
            _imagePath = picked.path;
          });
        }
      }
    }
  }

  // Obtiene el menu_id del restaurante
  Future<int?> _fetchMenuId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = AppConfig.getApiUrl(AppConfig.restauranteClienteDetalleEndpoint(widget.restauranteId));
    print('[VISTA][NPRODUCTO] Consultando menu_id en: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('[VISTA][NPRODUCTO] Respuesta detalle restaurante: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['menu_id'];
      }
    } catch (e) {
      print('[VISTA][NPRODUCTO] Error al obtener menu_id: $e');
    }
    return null;
  }

  Future<void> _guardarProducto() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final menuId = await _fetchMenuId();
    if (menuId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener el menú del restaurante')),
      );
      setState(() => _isSaving = false);
      return;
    }

    final url = AppConfig.getApiUrl(
      AppConfig.productosMenuRestauranteEndpoint(widget.restauranteId, menuId),
    );
    print('[VISTA][NPRODUCTO] URL POST producto: $url');

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['nombre'] = _nombreController.text;
    request.fields['precio'] = _precioController.text;
    request.fields['descripcion'] = _descripcionController.text;
    request.fields['tipo'] = widget.tipoProducto.toString();
    request.fields['disponible'] = '1'; // Cambiado: usar '1' para true en form-data

    print('[VISTA][NPRODUCTO] Datos enviados: ${request.fields}');

    if (_imageBytes != null) {
      print('[VISTA][NPRODUCTO] Imagen seleccionada: agregando archivo');
      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen',
          _imageBytes!,
          filename: _imagePath ?? 'producto.jpg',
        ),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('[VISTA][NPRODUCTO] Respuesta POST producto: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado correctamente')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar producto: ${response.body}')),
        );
      }
    } catch (e) {
      print('[VISTA][NPRODUCTO] Error al guardar producto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión al guardar producto')),
      );
    }
    setState(() => _isSaving = false);
  }

  String getProductImageUrl(String? imagen) {
    if (imagen == null || imagen.isEmpty) return '';
    if (imagen.startsWith('http')) return imagen;
    final url = '${AppConfig.storageBaseUrl}$imagen';
    print('[VISTA][NPRODUCTO] URL imagen producto: $url');
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tipo = widget.tipoProducto == 0 ? "Plato" : "Bebida";
    final disponible = true; // Por defecto disponible en la previsualización

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;
    final formMaxWidth = isWide ? 520.0 : screenWidth * 0.98;
    final horizontalPadding = isWide ? 32.0 : 8.0;
    final verticalPadding = isWide ? 40.0 : 16.0;

    return PopScope(
      canPop: true, // Permite regresar sin confirmación ya que es una pantalla secundaria
      child: Scaffold(
        appBar: AppBar(
          title: Text('Agregar $tipo'),
          backgroundColor: isDark ? Colors.black : Colors.red.shade700,
          elevation: 4,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
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
                  child: Column(
                    children: [
                      Text(
                        'Formulario de ${tipo.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nombreController,
                              decoration: InputDecoration(
                                labelText: 'Nombre del $tipo',
                                prefixIcon: Icon(
                                  widget.tipoProducto == 0 ? Icons.food_bank : Icons.local_drink,
                                  color: isDark ? Colors.white : Colors.red.shade700,
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.red.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Ingrese el nombre' : null,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _precioController,
                              decoration: InputDecoration(
                                labelText: 'Precio',
                                prefixIcon: Icon(Icons.attach_money, color: isDark ? Colors.white : Colors.red.shade700),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.red.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty ? 'Ingrese el precio' : null,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descripcionController,
                              decoration: InputDecoration(
                                labelText: 'Descripción',
                                prefixIcon: Icon(Icons.description, color: isDark ? Colors.white : Colors.red.shade700),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.red.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              maxLines: 3,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            // Centra el botón y elimina la ruta de la imagen
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.image),
                                label: const Text('Seleccionar imagen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _seleccionarImagen,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: _isSaving
                                  ? const Text('Guardando...')
                                  : Text('Guardar $tipo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 6,
                              ),
                              onPressed: _isSaving ? null : _guardarProducto,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Divider(thickness: 1.5, color: isDark ? Colors.red.shade900 : Colors.red.shade100),
                      const SizedBox(height: 12),
                      Text(
                        'Previsualización',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: isDark ? Colors.grey[850] : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _imageBytes != null
                                    ? Image.memory(
                                        _imageBytes!,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                                        child: Icon(
                                          widget.tipoProducto == 0 ? Icons.food_bank : Icons.local_drink,
                                          size: 38,
                                          color: Colors.red.shade400,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _nombreController.text.isEmpty
                                              ? 'Nombre del $tipo'
                                              : _nombreController.text,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: isDark ? Colors.white : Colors.red.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          disponible ? Icons.check_circle : Icons.cancel,
                                          color: disponible ? Colors.green : Colors.red,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _precioController.text.isEmpty
                                          ? '\$0.00'
                                          : '\$${_precioController.text}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? Colors.grey[300] : Colors.grey[800],
                                      ),
                                    ),
                                    if (_descripcionController.text.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Text(
                                          _descripcionController.text,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }
}
