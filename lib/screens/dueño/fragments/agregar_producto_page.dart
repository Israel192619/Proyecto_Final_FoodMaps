import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';

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

    return Scaffold(
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
                          Row(
                            children: [
                              ElevatedButton.icon(
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
                              const SizedBox(width: 12),
                              if (_imagePath != null)
                                Expanded(
                                  child: Text(
                                    _imagePath!,
                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: Text('Guardar $tipo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 6,
                            ),
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                // Aquí puedes implementar la lógica para guardar el producto
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$tipo guardado correctamente')),
                                );
                                Navigator.pop(context);
                              }
                            },
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
    );
  }
}
