import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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

  // Controladores para los campos del formulario
  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _celularController = TextEditingController();
  final _tematicaController = TextEditingController();
  int _estadoSeleccionado = 1; // 1 para abierto, 0 para cerrado

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
      final response = await http.post(
        Uri.parse('https://tuapi.com/api/restaurantes'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nombre_restaurante': _nombreController.text.trim(),
          'ubicacion': _ubicacionController.text.trim(),
          'celular': _celularController.text.trim(),
          'imagen': null,
          'estado': _estadoSeleccionado,
          'tematica': _tematicaController.text.trim(),
          'contador_vistas': 0,
          'user_id': _userId,
        }),
      ).timeout(const Duration(seconds: 30));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() => _isSuccess = true);
        _mostrarExito('Restaurante registrado exitosamente');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        throw Exception(responseData['message'] ?? 'Error al registrar restaurante');
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
              const SizedBox(height: 20),
              _buildEstadoSelector(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
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

  Widget _buildEstadoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado del restaurante:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Abierto'),
                selected: _estadoSeleccionado == 1,
                onSelected: (selected) => setState(() => _estadoSeleccionado = 1),
                selectedColor: Colors.green[300],
                labelStyle: TextStyle(
                  color: _estadoSeleccionado == 1 ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ChoiceChip(
                label: const Text('Cerrado'),
                selected: _estadoSeleccionado == 0,
                onSelected: (selected) => setState(() => _estadoSeleccionado = 0),
                selectedColor: Colors.red[300],
                labelStyle: TextStyle(
                  color: _estadoSeleccionado == 0 ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
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