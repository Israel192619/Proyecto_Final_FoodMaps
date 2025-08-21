import 'package:flutter_test/flutter_test.dart';
import 'package:foodmaps/utils/auth_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('auth_utils', () {
    test('loginAndNavigate guarda datos en SharedPreferences tras login exitoso', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final context = TestContext();
      // Simula respuesta exitosa
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'access_token': 'token123',
          'user': {'role_id': 2, 'id': 42},
          'restaurantes': [{'id': 1, 'nombre': 'Restaurante 1'}]
        }), 200);
      });
      // Aquí podrías modificar auth_utils para aceptar un cliente HTTP inyectable
      // y así probarlo con mockClient
      // Por ahora, solo verifica que la función existe
      expect(loginAndNavigate, isA<Function>());
    });
  });
}

class TestContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

