import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class EditarProductoPage extends StatefulWidget {
  final Map<String, dynamic> producto;
  final int restauranteId;
  final int menuId;

  const EditarProductoPage({
    Key? key,
    required this.producto,
    required this.restauranteId,
    required this.menuId,
  }) : super(key: key);

  @override
  State<EditarProductoPage> createState() => _EditarProductoPageState();
}

class _EditarProductoPageState extends State<EditarProductoPage> {
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _descripcionController;
  late bool _disponible;
  late int _tipoProducto;

  Uint8List? _imageBytes;
  String? _imagePath;
  String? _currentImageUrl;

  bool _isSaving = false;

  // Campos editables
  bool _editarNombre = false;
  bool _editarPrecio = false;
  bool _editarDescripcion = false;
  bool _editarDisponibilidad = false;
  bool _editarImagen = false;

  static const int _maxImageBytes = 2 * 1024 * 1024; // 2MB

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto['nombre_producto'] ?? '');
    _precioController = TextEditingController(text: widget.producto['precio']?.toString() ?? '');
    _descripcionController = TextEditingController(text: widget.producto['descripcion'] ?? '');
    _disponible = widget.producto['disponible'] == 1;
    _tipoProducto = widget.producto['tipo'] ?? 0;
    _currentImageUrl = getProductImageUrl(widget.producto['imagen']?.toString());
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String getProductImageUrl(String? imagen) {
    if (imagen == null || imagen.isEmpty) return '';
    if (imagen.startsWith('http')) return imagen;
    return '${AppConfig.storageBaseUrl}$imagen';
    if (imagen.startsWith('http')) return imagen;
    return '${AppConfig.storageBaseUrl}$imagen';
  }

  Future<void> _editarCampo(String campo) async {
    switch (campo) {
      case 'nombre':
        await _mostrarDialogoTexto(
          titulo: 'Editar nombre',
          controller: _nombreController,
          onGuardar: () => setState(() => _editarNombre = true),
        );
        break;
      case 'precio':
        await _mostrarDialogoTexto(
          titulo: 'Editar precio',
          controller: _precioController,
          keyboardType: TextInputType.number,
          onGuardar: () => setState(() => _editarPrecio = true),
        );
        break;
      case 'descripcion':
        await _mostrarDialogoTexto(
          titulo: 'Editar descripción',
          controller: _descripcionController,
          maxLines: 3,
          onGuardar: () => setState(() => _editarDescripcion = true),
        );
        break;
      case 'disponibilidad':
        await _mostrarDialogoDisponibilidad();
        break;
      case 'imagen':
        await _seleccionarImagen();
        break;
    }
  }

  Future<void> _mostrarDialogoTexto({
    required String titulo,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    required VoidCallback onGuardar,
  }) async {
    final tempController = TextEditingController(text: controller.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextFormField(
          controller: tempController,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(tempController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        controller.text = result;
        onGuardar();
      });
    }
  }

  Future<void> _mostrarDialogoDisponibilidad() async {
    bool tempDisponible = _disponible;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar disponibilidad'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SwitchListTile(
            title: const Text('Disponible'),
            value: tempDisponible,
            onChanged: (value) => setDialogState(() => tempDisponible = value),
            activeColor: Colors.red,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(tempDisponible),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _disponible = result;
        _editarDisponibilidad = true;
      });
    }
  }

  Future<void> _seleccionarImagen() async {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
         defaultTargetPlatform == TargetPlatform.linux ||
         defaultTargetPlatform == TargetPlatform.macOS);

    final picker = ImagePicker();
    const maxImageBytes = 2048 * 1024; // 2MB

    Future<void> setImageIfValid(Uint8List bytes, String nameOrPath) async {
      if (bytes.length > maxImageBytes) {
        img.Image? original = img.decodeImage(bytes);
        if (original == null) {
          _showCustomSnackBar(
            'No se pudo procesar la imagen seleccionada.',
            color: Colors.red.shade700,
            icon: Icons.broken_image,
          );
          return;
        }
        int targetWidth = original.width > 1024 ? 1024 : original.width;
        int targetHeight = (original.height * targetWidth / original.width).round();
        img.Image resized = img.copyResize(original, width: targetWidth, height: targetHeight);
        int quality = 85;
        Uint8List? resultBytes;
        for (; quality >= 40; quality -= 15) {
          resultBytes = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
          if (resultBytes.length <= maxImageBytes) break;
        }
        if (resultBytes != null && resultBytes.length <= maxImageBytes) {
          _showCustomSnackBar(
            'La imagen fue redimensionada automáticamente para cumplir el límite de 2MB.',
            color: Colors.blue.shade700,
            icon: Icons.photo_size_select_large,
          );
          setState(() {
            _imageBytes = resultBytes;
            _imagePath = nameOrPath;
            _editarImagen = true;
          });
          print('[VISTA][EDITAR_PRODUCTO] Imagen redimensionada (${resultBytes.length} bytes)');
        } else {
          _showCustomSnackBar(
            'No se pudo reducir la imagen por debajo de 2MB. Selecciona una imagen más pequeña.',
            color: Colors.red.shade700,
            icon: Icons.warning_amber_rounded,
          );
        }
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imagePath = nameOrPath;
        _editarImagen = true;
      });
      print('[VISTA][EDITAR_PRODUCTO] Imagen seleccionada (${bytes.length} bytes)');
    }

    if (kIsWeb) {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await setImageIfValid(bytes, picked.name);
      }
    } else if (isDesktop) {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await setImageIfValid(bytes, picked.path);
      }
    } else {
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
          await setImageIfValid(bytes, picked.path);
        }
      }
    }
  }

  void _limpiarImagenSeleccionada() {
    setState(() {
      _imageBytes = null;
      _imagePath = null;
      _editarImagen = false;
    });
    print('[VISTA][EDITAR_PRODUCTO] Imagen seleccionada limpiada');
  }

  void _showCustomSnackBar(String message, {Color? color, IconData? icon, int durationMs = 3500}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(message, style: const TextStyle(fontSize: 16))),
        ],
      ),
      backgroundColor: color ?? Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: Duration(milliseconds: durationMs),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _guardarCambios() async {
    // Verificar que al menos un campo esté seleccionado para editar
    if (!_editarNombre && !_editarPrecio && !_editarDescripcion && !_editarDisponibilidad && !_editarImagen) {
      _showCustomSnackBar(
        'Selecciona al menos un campo para editar',
        color: Colors.red.shade700,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final productoId = widget.producto['producto_id'];

    // Misma ruta para PUT/POST
    final endpoint = AppConfig.actualizarProductoEndpoint(
      widget.restauranteId, widget.menuId, productoId,
    );
    final url = AppConfig.getApiUrl(endpoint);

    // Determina si hay imagen para decidir método
    final hasImage = _editarImagen && _imageBytes != null;
    final method = hasImage ? 'POST' : 'PUT';
    print('[VISTA][EDITAR_PRODUCTO] URL $method producto: $url (hasImage=$hasImage)');

    // Prepara SIEMPRE los campos requeridos por el backend (editados o actuales)
    final nombreToSend = (_editarNombre ? _nombreController.text : (widget.producto['nombre_producto']?.toString() ?? '')).trim();
    final precioToSendStr = (_editarPrecio ? _precioController.text : (widget.producto['precio']?.toString() ?? '')).trim();
    final descripcionToSend = (_editarDescripcion ? _descripcionController.text : (widget.producto['descripcion']?.toString() ?? '')).trim();
    final disponibleBool = _editarDisponibilidad ? _disponible : (widget.producto['disponible'] == 1);
    final tipoToSend = widget.producto['tipo'] is int ? widget.producto['tipo'] as int : _tipoProducto;

    // Validación mínima local para evitar 422 obvios
    if (nombreToSend.isEmpty || precioToSendStr.isEmpty) {
      _showCustomSnackBar(
        'Nombre y precio son obligatorios',
        color: Colors.red.shade700,
        icon: Icons.warning_amber_rounded,
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      if (hasImage) {
        // Cuando hay imagen: multipart POST
        final request = http.MultipartRequest('POST', Uri.parse(url));
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        // Campos como strings en form-data
        request.fields['nombre'] = nombreToSend;
        request.fields['precio'] = precioToSendStr;
        request.fields['descripcion'] = descripcionToSend;
        request.fields['disponible'] = disponibleBool ? '1' : '0';
        request.fields['tipo'] = tipoToSend.toString();

        print('[VISTA][EDITAR_PRODUCTO] Headers multipart: ${request.headers}');
        print('[VISTA][EDITAR_PRODUCTO] Datos enviados (multipart): ${request.fields}');
        print('[VISTA][EDITAR_PRODUCTO] Enviando imagen en multipart');

        request.files.add(
          http.MultipartFile.fromBytes(
            'imagen',
            _imageBytes!,
            filename: _imagePath ?? 'producto_actualizado.jpg',
          ),
        );

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        print('[VISTA][EDITAR_PRODUCTO] Respuesta $method producto: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showCustomSnackBar(
            '¡Producto actualizado correctamente!',
            color: Colors.green.shade600,
            icon: Icons.check_circle_outline,
          );
          Navigator.pop(context, true);
        } else {
          String userMessage = 'Error al actualizar producto.';
          if (response.statusCode == 422) {
            userMessage = 'Verifica los datos ingresados. La imagen debe pesar menos de 2MB.';
          }
          _showCustomSnackBar(
            userMessage,
            color: Colors.red.shade700,
            icon: Icons.error_outline,
          );
        }
      } else {
        // Sin imagen: PUT con JSON (no uses Multipart PUT porque Laravel no lee bien campos en PUT multipart)
        final headers = <String, String>{
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        };

        final payload = {
          'nombre': nombreToSend,
          'precio': double.tryParse(precioToSendStr) ?? precioToSendStr, // num o string
          'descripcion': descripcionToSend,
          'disponible': disponibleBool, // booleano real para JSON
          'tipo': tipoToSend,          // int
        };

        print('[VISTA][EDITAR_PRODUCTO] Headers JSON: $headers');
        print('[VISTA][EDITAR_PRODUCTO] Payload JSON enviado: $payload');

        final response = await http.put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(payload),
        );

        print('[VISTA][EDITAR_PRODUCTO] Respuesta PUT producto: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showCustomSnackBar(
            '¡Producto actualizado correctamente!',
            color: Colors.green.shade600,
            icon: Icons.check_circle_outline,
          );
          Navigator.pop(context, true);
        } else {
          _showCustomSnackBar(
            'Error al actualizar producto.',
            color: Colors.red.shade700,
            icon: Icons.error_outline,
          );
        }
      }
    } catch (e) {
      print('[VISTA][EDITAR_PRODUCTO] Error al actualizar producto: $e');
      _showCustomSnackBar(
        'No se pudo conectar con el servidor. Intenta nuevamente.',
        color: Colors.red.shade700,
        icon: Icons.cloud_off,
      );
    }

    setState(() => _isSaving = false);
  }

  Widget _buildEditableCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasChanges = _editarNombre || _editarPrecio || _editarDescripcion || _editarDisponibilidad || _editarImagen;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 560; // umbral para apilar
        final double imageSize = isNarrow ? 120 : 100;

        final imageWidget = GestureDetector(
          onTap: () => _editarCampo('imagen'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _editarImagen ? Colors.orange : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                width: _editarImagen ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  SizedBox(
                    width: imageSize,
                    height: imageSize,
                    child: _editarImagen && _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                            ? Image.network(
                                _currentImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                                  child: Icon(
                                    _tipoProducto == 0 ? Icons.food_bank : Icons.local_drink,
                                    size: 50,
                                    color: Colors.red.shade400,
                                  ),
                                ),
                              )
                            : Container(
                                color: isDark ? Colors.grey[700] : Colors.grey[200],
                                child: Icon(
                                  _tipoProducto == 0 ? Icons.food_bank : Icons.local_drink,
                                  size: 50,
                                  color: Colors.red.shade400,
                                ),
                              ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final imageActions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: _seleccionarImagen,
              icon: const Icon(Icons.image, size: 18),
              label: const Text('Cambiar'),
            ),
            if (_imageBytes != null) ...[
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _limpiarImagenSeleccionada,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Quitar'),
              ),
            ],
          ],
        );

        final nombreWidget = GestureDetector(
          onTap: () => _editarCampo('nombre'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _editarNombre ? Colors.orange.withOpacity(0.2) : (isDark ? Colors.grey[800]?.withOpacity(0.3) : Colors.red.shade50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _editarNombre ? Colors.orange : (isDark ? Colors.grey[700]! : Colors.red.shade100),
                width: _editarNombre ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _nombreController.text.isEmpty ? 'Sin nombre' : _nombreController.text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.red.shade700,
                    ),
                  ),
                ),
                Icon(Icons.edit, size: 16, color: _editarNombre ? Colors.orange : Colors.grey),
                if (_editarNombre) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle, size: 16, color: Colors.orange),
                ],
              ],
            ),
          ),
        );

        final descripcionWidget = GestureDetector(
          onTap: () => _editarCampo('descripcion'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: _editarDescripcion ? Colors.orange.withOpacity(0.2) : (isDark ? Colors.grey[800]?.withOpacity(0.3) : Colors.red.shade50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _editarDescripcion ? Colors.orange : (isDark ? Colors.grey[700]! : Colors.red.shade100),
                width: _editarDescripcion ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _descripcionController.text.isEmpty ? 'Sin descripción' : _descripcionController.text,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.3),
                  ),
                ),
                Icon(Icons.edit, size: 16, color: _editarDescripcion ? Colors.orange : Colors.grey),
                if (_editarDescripcion) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle, size: 16, color: Colors.orange),
                ],
              ],
            ),
          ),
        );

        final disponibilidadWidget = GestureDetector(
          onTap: () => _editarCampo('disponibilidad'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _editarDisponibilidad ? Colors.orange.withOpacity(0.2) : (_disponible ? Colors.green.shade100 : Colors.red.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _editarDisponibilidad ? Colors.orange : (_disponible ? Colors.green.shade300 : Colors.red.shade300),
                width: _editarDisponibilidad ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _disponible ? Icons.check_circle : Icons.cancel,
                  color: _editarDisponibilidad ? Colors.orange : (_disponible ? Colors.green.shade700 : Colors.red.shade700),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _disponible ? 'Disponible' : 'No disponible',
                  style: TextStyle(
                    fontSize: 12,
                    color: _editarDisponibilidad ? Colors.orange : (_disponible ? Colors.green.shade700 : Colors.red.shade700),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );

        final precioWidget = GestureDetector(
          onTap: () => _editarCampo('precio'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: _editarPrecio
                  ? LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: (_editarPrecio ? Colors.orange : Colors.red).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bs. ${_precioController.text.isEmpty ? '0' : _precioController.text}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (_editarPrecio) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle, size: 16, color: Colors.white),
                ],
              ],
            ),
          ),
        );

        final leftBlock = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            imageWidget,
            const SizedBox(height: 10),
            precioWidget, // Precio debajo de la imagen (alineado con diseño de dueño)
            const SizedBox(height: 8),
            imageActions,
          ],
        );

        final middleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nombreWidget,
            const SizedBox(height: 12),
            descripcionWidget,
          ],
        );

        final rightBlock = ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              disponibilidadWidget,
            ],
          ),
        );

        final content = isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftBlock,
                  const SizedBox(height: 16),
                  middleBlock,
                  const SizedBox(height: 16),
                  rightBlock,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftBlock,
                  const SizedBox(width: 16),
                  Expanded(child: middleBlock),
                  const SizedBox(width: 16),
                  rightBlock,
                ],
              );

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Card(
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: hasChanges ? Colors.orange : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                width: hasChanges ? 3 : 1,
              ),
            ),
            color: isDark ? Colors.grey[850] : Colors.white,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isDark
                    ? LinearGradient(colors: [Colors.grey[800]!, Colors.grey[850]!], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                    : LinearGradient(colors: [Colors.white, Colors.red.shade50], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tipo = _tipoProducto == 0 ? "Plato" : "Bebida";
    final hasChanges = _editarNombre || _editarPrecio || _editarDescripcion || _editarDisponibilidad || _editarImagen;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Editar $tipo'),
          backgroundColor: isDark ? Colors.black : Colors.red.shade700,
          elevation: 4,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth < 500 ? constraints.maxWidth * 0.98 : 420;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Toca cualquier parte del producto para editarla',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _buildEditableCard(),
                            if (hasChanges) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tienes cambios pendientes. Presiona "Guardar cambios" para aplicarlos.',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Descartar cambios'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.grey[600],
                                        side: BorderSide(color: Colors.grey[400]!),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _nombreController.text = widget.producto['nombre_producto'] ?? '';
                                          _precioController.text = widget.producto['precio']?.toString() ?? '';
                                          _descripcionController.text = widget.producto['descripcion'] ?? '';
                                          _disponible = widget.producto['disponible'] == 1;
                                          _editarNombre = false;
                                          _editarPrecio = false;
                                          _editarDescripcion = false;
                                          _editarDisponibilidad = false;
                                          _editarImagen = false;
                                          _imageBytes = null;
                                          _imagePath = null;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: _isSaving ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      ) : const Icon(Icons.save),
                                      label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 6,
                                      ),
                                      onPressed: _isSaving ? null : _guardarCambios,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
