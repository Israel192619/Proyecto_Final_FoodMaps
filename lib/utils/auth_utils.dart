import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodmaps/config/config.dart';

Future<void> loginAndNavigate(BuildContext context, String username, String password) async {
  final String apiUrl = AppConfig.getApiUrl(AppConfig.loginEndpoint);

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    print('[AUTHWRAPPER] Respuesta login statusCode: ${response.statusCode}');
    print('[AUTHWRAPPER] Respuesta login body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
      final data = jsonDecode(response.body);
      print('[AUTHWRAPPER] Login exitoso, data: $data');
      final token = data['access_token'];
      final user = data['user'];
      final roleId = user['role_id'];
      final userId = user['id'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      await prefs.setBool('mantenersesion', true);
      await prefs.setInt('userRole', roleId);
      await prefs.setInt('user_id', userId);

      if (roleId == 2) {
        // Puede venir como 'restaurantes' o 'restaurante'
        var restaurantes = data['restaurantes'] ?? data['restaurante'];
        print('[AUTHWRAPPER] Restaurantes obtenidos tras login: $restaurantes');
        // --- Unifica la lista de restaurantes ---
        List<dynamic> restaurantesList = [];
        if (restaurantes is List) {
          restaurantesList = restaurantes;
        } else if (restaurantes is Map) {
          restaurantesList = [restaurantes];
        }
        await prefs.setString('restaurantes', jsonEncode(restaurantesList));
        if (restaurantesList.length > 1) {
          print('[AUTHWRAPPER] Dueño tiene más de un restaurante, redirigiendo a /restaurante_selector');
          print('[VISTA] [REDIR] Redirigiendo a /restaurante_selector desde auth_utils');
          Navigator.pushReplacementNamed(
            context,
            '/restaurante_selector',
            arguments: restaurantesList,
          );
          return;
        }
        // Si solo hay uno, selecciona ese restaurante
        if (restaurantesList.isNotEmpty) {
          final onlyRest = restaurantesList.first;
          await prefs.setInt('restaurante_id', onlyRest['id']);
          await prefs.setString('restaurante_seleccionado', jsonEncode(onlyRest));
          await prefs.setBool('hasRestaurant', true);
          print('[AUTHWRAPPER] Dueño redirigido a /dueno_home con restaurante: $onlyRest');
          print('[VISTA] [REDIR] Redirigiendo a /dueno_home desde auth_utils');
          Navigator.pushReplacementNamed(
            context,
            '/dueno_home',
            arguments: onlyRest,
          );
          return;
        }
      }

      switch (response.statusCode) {
        case 200:
          await prefs.setBool('hasRestaurant', true);
          print('[AUTHWRAPPER] Cliente redirigido a /home');
          print('[VISTA] [REDIR] Redirigiendo a /home desde auth_utils');
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 201:
          await prefs.setBool('hasRestaurant', false);
          print('[AUTHWRAPPER] Dueño sin restaurante redirigido a /new_restaurante');
          print('[VISTA] [REDIR] Redirigiendo a /new_restaurante desde auth_utils');
          Navigator.pushReplacementNamed(context, '/new_restaurante');
          break;
        case 202:
          final restaurante = data['restaurante'];
          await prefs.setBool('hasRestaurant', true);
          await prefs.setString('restaurante', jsonEncode(restaurante));
          await prefs.setInt('restaurante_id', restaurante['id']);
          print('[AUTHWRAPPER] Dueño redirigido a /dueno_home con restaurante: $restaurante');
          print('[VISTA] [REDIR] Redirigiendo a /dueno_home desde auth_utils');
          Navigator.pushReplacementNamed(
            context,
            '/dueno_home',
            arguments: restaurante,
          );
          break;
        default:
          print('[AUTHWRAPPER] Respuesta inesperada del servidor en login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Respuesta inesperada del servidor')),
          );
      }
    } else if (response.statusCode == 401) {
      print('[AUTHWRAPPER] Credenciales inválidas en login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales inválidas')),
      );
    } else {
      print('[AUTHWRAPPER] Error del servidor en login: ${response.statusCode}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error del servidor: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('[AUTHWRAPPER] Error de conexión en login: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error de conexión: ${e.toString()}')),
    );
  }
}

/// Obtiene la lista de restaurantes del dueño usando el token y el endpoint privado
Future<List<dynamic>> getRestaurantesDelDueno(String token) async {
  final String url = AppConfig.apiBaseUrl + "/restaurantes";
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token,
      },
    );
    print('[GET RESTAURANTES DUEÑO] statusCode: \'${response.statusCode}\'');
    print('[GET RESTAURANTES DUEÑO] body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // --- NUEVO: Extraer lista desde 'data' si existe ---
      if (data is Map && data.containsKey('data')) {
        if (data['data'] is List) {
          return data['data'];
        } else if (data['data'] is Map) {
          return [data['data']];
        }
      }
      // Compatibilidad con otros formatos
      if (data is List) {
        return data;
      } else if (data is Map && data.containsKey('restaurantes')) {
        return data['restaurantes'] is List ? data['restaurantes'] : [data['restaurantes']];
      }
    }
    return [];
  } catch (e) {
    print('[GET RESTAURANTES DUEÑO] Error: $e');
    return [];
  }
}
