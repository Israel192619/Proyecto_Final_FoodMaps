import 'dart:io';
import 'dart:convert';
import 'dart:async';

// Lista para guardar los clientes conectados
final List<WebSocket> clientesConectados = [];

// Función principal asincrónica
void main() async {
  // Inicia un servidor HTTP en localhost:4040
  final server = await HttpServer.bind('127.0.0.1', 4040);
  print('Servidor WebSocket escuchando en ws://127.0.0.1:4040');

  // Simula cambios de estado cada 5 segundos
  Timer.periodic(Duration(seconds: 5), (timer) {
    // Simula datos de estado de restaurante
    final estadoRestaurante = {
      'restaurante_id': 1,
      'estado': timer.tick % 2, // Alterna entre 0 y 1
      'timestamp': DateTime.now().toIso8601String(),
    };
    final mensaje = jsonEncode(estadoRestaurante);
    // Envía el estado a todos los clientes conectados
    for (var ws in clientesConectados) {
      ws.add(mensaje);
    }
    print('Enviado a clientes: $mensaje');
  });

  // Espera por cada solicitud HTTP entrante
  await for (HttpRequest req in server) {
    // Verifica si la solicitud es para actualizar a WebSocket
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      // Convierte la solicitud HTTP en una conexión WebSocket
      WebSocketTransformer.upgrade(req).then((WebSocket ws) {
        print('Cliente conectado');
        clientesConectados.add(ws);

        // Escucha los mensajes enviados por el cliente
        ws.listen((data) {
          print('Recibido del cliente: $data');
          // Puedes procesar mensajes del cliente aquí si lo necesitas
        }, onDone: () {
          // Cuando el cliente se desconecta, lo elimina de la lista
          clientesConectados.remove(ws);
          print('Cliente desconectado');
        });
      });
    } else {
      // Si no es una solicitud WebSocket, responde con prohibido
      req.response
        ..statusCode = HttpStatus.forbidden
        ..close();
    }
  }
}
