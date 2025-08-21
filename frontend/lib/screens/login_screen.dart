import 'dart:async';

import 'package:foodmaps/constants/assets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodmaps/config/config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool obscureText = true;

  @override
  void initState() {
    super.initState();
    print('[VISTA LOGIN] INITSTATE');
    _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');
    final savedPassword = prefs.getString('password');
    final keepSession = prefs.getBool('mantenersesion') ?? false;

    // Solo hacer auto-login si el usuario eligió mantener la sesión
    if (keepSession && savedUsername != null && savedPassword != null) {
      _attemptAutoLogin(savedUsername, savedPassword);
    }
  }

  Future<void> _attemptAutoLogin(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.getApiUrl(AppConfig.loginEndpoint)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Redirigir al home y limpiar el stack de navegación
        Navigator.pushNamedAndRemoveUntil(
            context,
            '/mapsCliActivity',
                (route) => false
        );
      } else {
        // Si el auto-login falla, limpiar las credenciales
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('username');
        await prefs.remove('password');
      }
    } catch (e) {
      print('Auto-login fallido: $e');
      // Limpiar credenciales si hay error
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');
      await prefs.remove('password');
    }
  }

  Future<void> _login() async {
    if (_isLoading) return; // Evita doble pulsación
    if (!_formKey.currentState!.validate()) return;

    String username = _usernameController.text;
    String password = _passwordController.text;

    final String apiUrl = AppConfig.getApiUrl(AppConfig.loginEndpoint);

    try {
      setState(() => _isLoading = true);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final prefs = await SharedPreferences.getInstance();

      // Resetear estado de logout forzado al intentar login
      await prefs.setBool('forcedLogout', false);

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final user = data['user'];
        final roleId = user['role_id'];
        final userId = user['id'];

        await prefs.setString('auth_token', token);
        await prefs.setString('username', username);
        await prefs.setString('password', password);
        await prefs.setBool('mantenersesion', true);
        await prefs.setInt('userRole', roleId);
        await prefs.setInt('user_id', userId);

        // --- MODIFICADO: Obtener restaurantes desde API si es dueño ---
        if (roleId == 2) {
          final restaurantesUrl = '${AppConfig.apiBaseUrl}/restaurantes';
          final restaurantesResp = await http.get(
            Uri.parse(restaurantesUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          print('[VISTA LOGIN] GET /api/restaurantes status: ${restaurantesResp.statusCode}');
          print('[VISTA LOGIN] GET /api/restaurantes body: ${restaurantesResp.body}');
          if (restaurantesResp.statusCode == 200) {
            final restaurantesData = jsonDecode(restaurantesResp.body);
            List<dynamic> restaurantesList = [];
            if (restaurantesData is Map && restaurantesData.containsKey('data')) {
              restaurantesList = restaurantesData['data'] is List
                ? restaurantesData['data']
                : [];
            }
            await prefs.setString('restaurantes', jsonEncode(restaurantesList));
            print('[VISTA LOGIN] Restaurantes guardados en SharedPreferences: $restaurantesList');

            // Manejo de selección y navegación
            if (restaurantesList.length > 1) {
              final savedRestId = prefs.getInt('restaurante_id');
              if (savedRestId != null && restaurantesList.any((r) => r['id'] == savedRestId)) {
                final selectedRest = restaurantesList.firstWhere((r) => r['id'] == savedRestId);
                await prefs.setString('restaurante_seleccionado', jsonEncode(selectedRest));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inicio de sesión exitoso'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/dueno_home',
                  (route) => false,
                  arguments: selectedRest,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inicio de sesión exitoso'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/restaurante_selector',
                  (route) => false,
                  arguments: restaurantesList,
                );
                final selected = await Navigator.pushNamed(
                  context,
                  '/restaurante_selector',
                  arguments: restaurantesList,
                );
                if (selected != null && selected is Map && selected['id'] != null) {
                  await prefs.setInt('restaurante_id', selected['id']);
                  await prefs.setString('restaurante_seleccionado', jsonEncode(selected));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restaurante seleccionado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dueno_home',
                    (route) => false,
                    arguments: selected,
                  );
                }
              }
              return;
            } else if (restaurantesList.length == 1) {
              await prefs.setInt('restaurante_id', restaurantesList[0]['id']);
              await prefs.setString('restaurante_seleccionado', jsonEncode(restaurantesList[0]));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inicio de sesión exitoso'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/dueno_home',
                (route) => false,
                arguments: restaurantesList[0],
              );
              return;
            }
          }
        }

        // Manejar diferentes respuestas del servidor
        switch (response.statusCode) {
          case 200: // Cliente
            await prefs.setBool('hasRestaurant', true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inicio de sesión exitoso'),
                backgroundColor: Colors.green,
              ),
            );
            print('[VISTA LOGIN] [REDIR] Redirigiendo a /mapsCliActivity');
            Navigator.pushNamedAndRemoveUntil(context, '/mapsCliActivity', (route) => false);
            break;

          case 201: // Dueño sin restaurante
            await prefs.setBool('hasRestaurant', false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inicio de sesión exitoso'),
                backgroundColor: Colors.green,
              ),
            );
            print('[VISTA LOGIN] [REDIR] Redirigiendo a /new_restaurante');
            Navigator.pushNamedAndRemoveUntil(context, '/new_restaurante', (route) => false);
            break;

          case 202: // Dueño con restaurante
            final restaurante = data['restaurante'];
            await prefs.setBool('hasRestaurant', true);
            await prefs.setString('restaurante', jsonEncode(restaurante));
            await prefs.setInt('restaurante_id', restaurante['id']);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Inicio de sesión exitoso'),
                backgroundColor: Colors.green,
              ),
            );
            print('[VISTA LOGIN] [REDIR] Redirigiendo a /dueno_home con restaurante: $restaurante');
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/dueno_home',
              (route) => false,
              arguments: restaurante,
            );
            break;

          default:
            print('[VISTA LOGIN] [REDIR] Respuesta inesperada del servidor');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ocurrió un problema inesperado. Intenta nuevamente.'),
                backgroundColor: Colors.red,
              ),
            );
        }
      }
      else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales inválidas. Verifica tus datos.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo conectar con el servidor. Intenta más tarde.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiempo de espera agotado. Verifica tu conexión.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión. Revisa tu internet.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



// y al iniciar la aplicación en el AuthWrapper

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: screenWidth > 600 ? 400 : double.infinity,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        Assets.logo,
                        height: screenHeight * 0.2,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      const Text(
                        'FOODMAPS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      const Text(
                        'INICIAR SESIÓN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Usuario:',
                          prefixIcon: Icon(Icons.person, color: Colors.red),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingrese su usuario';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          labelText: 'Contraseña:',
                          prefixIcon: const Icon(Icons.lock, color: Colors.red),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingrese su contraseña';
                          } else if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_isLoading) return;
                                _login();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.2 > 200 ? 50 : screenWidth * 0.2,
                            vertical: screenHeight * 0.015,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                              )
                            : const Text(
                                'Ingresar',
                                style: TextStyle(color: Colors.red),
                              ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      const Text("¿No tienes una cuenta aún?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text(
                          "Click aquí para crear una",
                          style: TextStyle(color: Colors.blue),
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
