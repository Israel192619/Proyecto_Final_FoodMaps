import 'dart:io';
import 'dart:convert';

// Función principal asincrónica
void main() async {
  // Conecta al servidor WebSocket en localhost:4040
  final ws = await WebSocket.connect('ws://127.0.0.1:4040');
  print('Conectado al servidor WebSocket');

  // Escucha los mensajes recibidos del servidor
  ws.listen((data) {
    print('Recibido del servidor: $data');
    // Intenta decodificar el mensaje como JSON
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map && decoded.containsKey('restaurante_id') && decoded.containsKey('estado')) {
        final id = decoded['restaurante_id'];
        final estado = decoded['estado'] == 1 ? 'Abierto' : 'Cerrado';
        print('Restaurante $id está ahora: $estado');
      }
    } catch (e) {
      print('Mensaje no es JSON válido o no contiene estado: $e');
    }
  });

  // Envía un mensaje al servidor (puedes omitir si solo quieres escuchar)
  ws.add('Cliente conectado para escuchar estados de restaurantes');
  // Mantén la conexión abierta
  await Future.delayed(Duration(minutes: 10));
  ws.close();
}
