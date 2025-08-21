import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:foodmaps/config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Nuevo controlador
  final TextEditingController _pass1Controller = TextEditingController();
  final TextEditingController _pass2Controller = TextEditingController();

  bool _loading = false;
  String? _selectedRol;

  @override
  void initState() {
    super.initState();
    print('[VISTA REGISTRO] INITSTATE');
  }

  Future<void> _registrar() async {
    if (_loading) return; // Evita doble pulsación
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      final String apiUrl = AppConfig.getApiUrl(AppConfig.registerEndpoint);

      try {
        // Ajusta el rol para que sea "Cliente" o "Dueño"
        String? rolBackend;
        if (_selectedRol == 'cliente') {
          rolBackend = 'Cliente';
        } else if (_selectedRol == 'dueño') {
          rolBackend = 'Dueño';
        }

        print('[VISTA REGISTRO] Enviando registro a $apiUrl');
        print('[VISTA REGISTRO] Datos enviados: username=${_usernameController.text.trim()}, celular=${_celularController.text.trim()}, email=${_emailController.text.trim()}, rol=$rolBackend');

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text.trim(),
            'celular': _celularController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _pass1Controller.text.trim(),
            'password_confirmation': _pass2Controller.text.trim(),
            'rol': rolBackend,
          }),
        );

        print('[VISTA REGISTRO] Respuesta registro statusCode: ${response.statusCode}');
        print('[VISTA REGISTRO] Respuesta registro body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          print('[VISTA REGISTRO] Registro exitoso, data: $data');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registro exitoso'),
              backgroundColor: Colors.green,
            ),
          );
          // Guardar credenciales en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', _usernameController.text.trim());
          await prefs.setString('password', _pass1Controller.text.trim());
          await prefs.setBool('mantenersesion', true);

          // Login automático después del registro exitoso
          print('[VISTA REGISTRO] Login automático después de registro');
          await _loginAfterRegister(
            _usernameController.text.trim(),
            _pass1Controller.text.trim(),
          );
        } else {
          String msg = 'Ocurrió un error en el registro. Intenta nuevamente.';
          try {
            final data = jsonDecode(response.body);
            if (data is Map && data['message'] != null) {
              // Puedes personalizar el mensaje si el backend lo provee
              msg = 'Error: ' + data['message'].toString();
            }
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('[VISTA REGISTRO] Error de conexión en registro: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión. Revisa tu internet.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginAfterRegister(String username, String password) async {
    final String apiUrl = AppConfig.getApiUrl(AppConfig.loginEndpoint);

    print('[VISTA REGISTRO] Login automático post-registro a $apiUrl');
    print('[VISTA REGISTRO] Credenciales usadas: username=$username, password=$password');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('[VISTA REGISTRO] Respuesta login statusCode: ${response.statusCode}');
      print('[VISTA REGISTRO] Respuesta login body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        final data = jsonDecode(response.body);
        print('[VISTA REGISTRO] Login exitoso, data: $data');
        final token = data['access_token'];
        final user = data['user'];
        final roleId = user['role_id'];
        final userId = user['id']; // <-- Obtener el id

        // Guardar credenciales
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('username', username);
        await prefs.setString('password', password);
        await prefs.setBool('mantenersesion', true);
        await prefs.setInt('userRole', roleId);
        await prefs.setInt('user_id', userId); // <-- Guardar el id
        await prefs.setBool('forcedLogout', false); // <-- LIMPIA EL FLAG AQUÍ

        // Manejar diferentes respuestas del servidor
        switch (response.statusCode) {
          case 200: // Cliente
            await prefs.setBool('hasRestaurant', true);
            if (mounted) {
              print('[VISTA REGISTRO] [REDIR] Redirigiendo a /home');
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
            break;
          case 201: // Dueño sin restaurante
            await prefs.setBool('hasRestaurant', false);
            if (mounted) {
              print('[VISTA REGISTRO] [REDIR] Redirigiendo a /new_restaurante');
              Navigator.pushNamedAndRemoveUntil(context, '/new_restaurante', (route) => false);
            }
            break;
          case 202: // Dueño con restaurante
            final restaurante = data['restaurante'];
            await prefs.setBool('hasRestaurant', true);
            await prefs.setString('restaurante', jsonEncode(restaurante));
            if (mounted) {
              print('[VISTA REGISTRO] [REDIR] Redirigiendo a /dueno_home con restaurante: $restaurante');
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/dueno_home',
                (route) => false,
                arguments: restaurante,
              );
            }
            break;
          default:
            if (mounted) {
              print('[VISTA REGISTRO] [REDIR] Respuesta inesperada del servidor en login');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ocurrió un problema inesperado. Intenta nuevamente.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
        }
      } else if (response.statusCode == 401) {
        print('[VISTA REGISTRO] Credenciales inválidas en login');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Credenciales inválidas. Verifica tus datos.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('[VISTA REGISTRO] Error del servidor en login: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo conectar con el servidor. Intenta más tarde.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('[VISTA REGISTRO] Error de conexión en login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión. Revisa tu internet.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black, Colors.grey.shade900]
                : [Colors.white, Colors.red.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      "REGISTRARSE",
                      style: TextStyle(
                        fontSize: 40,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Nombre de usuario
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person, color: textColor),
                        hintText: "Nombre de usuario",
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        labelStyle: TextStyle(color: textColor),
                      ),
                      style: TextStyle(fontSize: 18, color: textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un nombre de usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Celular
                    TextFormField(
                      controller: _celularController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.phone, color: textColor),
                        hintText: "Celular",
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        labelStyle: TextStyle(color: textColor),
                      ),
                      style: TextStyle(fontSize: 18, color: textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un número de celular';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Correo electrónico
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: textColor),
                        hintText: "Email",
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        labelStyle: TextStyle(color: textColor),
                      ),
                      style: TextStyle(fontSize: 18, color: textColor),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Ingrese un email válido';
                        }
                        if (value.length < 5) {
                          return 'El email debe tener al menos 5 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Contraseña
                    TextFormField(
                      controller: _pass1Controller,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock, color: textColor),
                        hintText: "Contraseña",
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        labelStyle: TextStyle(color: textColor),
                      ),
                      style: TextStyle(fontSize: 18, color: textColor),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Repetir contraseña
                    TextFormField(
                      controller: _pass2Controller,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline, color: textColor),
                        hintText: "Repita su contraseña",
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        labelStyle: TextStyle(color: textColor),
                      ),
                      style: TextStyle(fontSize: 18, color: textColor),
                      validator: (value) {
                        if (value != _pass1Controller.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Selección de rol
                    DropdownButtonFormField<String>(
                      value: _selectedRol,
                      dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person_outline, color: textColor),
                        hintText: "Seleccione su rol",
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                        labelStyle: TextStyle(color: textColor),
                      ),
                      iconEnabledColor: Colors.red,
                      style: TextStyle(
                        fontSize: 18,
                        color: textColor,
                      ),
                      selectedItemBuilder: (context) {
                        return [
                          Text(
                            'Cliente',
                            style: TextStyle(
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'Dueño',
                            style: TextStyle(
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                        ];
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'cliente',
                          child: Text(
                            'Cliente',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'dueño',
                          child: Text(
                            'Dueño',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRol = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Seleccione un rol';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    // Botón de registro
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _registrar,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _loading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                "REGISTRAR",
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Texto de navegación a la pantalla de login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "¿Ya tienes una cuenta? ",
                          style: TextStyle(fontSize: 16, color: textColor),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: Text(
                            "Iniciar sesión",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
