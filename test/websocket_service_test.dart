import 'package:flutter_test/flutter_test.dart';
import 'package:foodmaps/services/websocket_service.dart';

void main() {
  group('WebSocketService', () {
    test('Se puede crear una instancia', () {
      final service = WebSocketService();
      expect(service, isNotNull);
    });
    // Agrega aquí más pruebas de integración según la lógica del servicio
  });
}

