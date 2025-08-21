import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';



class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  PusherChannelsFlutter? pusher;
  bool _isConnected = false;

  Future<void> initializePusher() async {
    try {
      // Configuración para tu servidor Reverb
      pusher = PusherChannelsFlutter.getInstance();

      await pusher!.init(
        apiKey: 'f70zdychxrkeuixgvhwz', // Tu REVERB_APP_KEY
        cluster: '', // Vacío para servidor local
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: onEvent,
        onSubscriptionError: onSubscriptionError,
        onDecryptionFailure: onDecryptionFailure,
        onMemberAdded: onMemberAdded,
        onMemberRemoved: onMemberRemoved,
       
      );

      await pusher!.connect();
      print('Pusher inicializado correctamente');
    } catch (e) {
      print('Error al inicializar Pusher: $e');
    }
  }


  // Callbacks
  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print('Estado de conexión cambió: $previousState -> $currentState');
    _isConnected = currentState == 'CONNECTED';
  }

  void onError(String message, int? code, dynamic e) {
    print('Error de Pusher: $message (código: $code)');
  }

  void onEvent(PusherEvent event) {
    print('Evento recibido: ${event.eventName}');
    print('Canal: ${event.channelName}');
    print('Datos: ${event.data}');

    // Aquí puedes manejar diferentes tipos de eventos
    if (event.eventName == 'testingEvent') {
      handleTestingEvent(event.data);
    }
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print('Suscripción exitosa al canal: $channelName');
  }

  void onSubscriptionError(String message, dynamic e) {
    print('Error en suscripción: $message');
  }

  void onDecryptionFailure(String event, String reason) {
    print('Fallo de descifrado: $event - $reason');
  }

  void onMemberAdded(String channelName, PusherMember member) {
    print('Miembro añadido: ${member.userInfo}');
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    print('Miembro removido: ${member.userInfo}');
  }

  // Manejar evento específico
  void handleTestingEvent(String data) {
    print('Evento de prueba recibido: $data');
    // Aquí puedes actualizar la UI, mostrar notificaciones, etc.
  }

  // Desconectar
  Future<void> disconnect() async {
    await pusher!.disconnect();
    _isConnected = false;
  }

  bool get isConnected => _isConnected;
}