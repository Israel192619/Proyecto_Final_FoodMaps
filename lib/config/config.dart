// lib/config/config.dart
class AppConfig {
  static const String apiBaseUrl = 'http://192.168.100.9:8081/FoodMaps_API_I/FoodMaps_API/public/api';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';

  // Endpoints para clientes
  static const String restaurantesClienteEndpoint = '/clientes/restaurantes';
  static String restauranteClienteDetalleEndpoint(int id) => '/clientes/restaurantes/$id';

  // Endpoint para cambiar estado restaurante (dueño)
  static String restauranteChangeStatusEndpoint(int id) {
    final ruta = '/restaurantes/$id/change-status';
    print('[WSO][RUTA] restauranteChangeStatusEndpoint: $ruta');
    return ruta;
  }

  // Endpoint para obtener el estado actual del restaurante (dueño)
  static String restauranteStatusEndpoint(int id) {
    final ruta = '/restaurantes/$id/status';
    print('[WSO][RUTA] restauranteStatusEndpoint: $ruta');
    return ruta;
  }

  // --- WebSocket para estados en tiempo real ---
  // Revisa que la clave "app/f70zdychxrkeuixgvhwz" coincida con la configurada en tu backend (pusher/reverb)
  static const String websocketBaseUrl = 'ws://192.168.100.9:9000';
  static const String websocketFullUrl = 'ws://192.168.100.9:9000/app/f70zdychxrkeuixgvhwz?protocol=7&client=js&version=7.0.3&flash=false';
  // static const String websocketFullUrl = 'ws://192.168.100.9:9000/app/l1zohmfj7ixc9fccl6ef?protocol=7&client=js&version=7.0.3&flash=false';

  static String getWebSocketUrl() {
    print('[WSO][RUTA] getWebSocketUrl: $websocketFullUrl');
    return websocketFullUrl;
  }

  // Endpoint para escuchar eventos de estado en tiempo real
  static String websocketEventsEndpoint() {
    final ruta = '$websocketBaseUrl/events';
    print('[WSO][RUTA] websocketEventsEndpoint: $ruta');
    return ruta;
  }

  // Endpoint para actualizar estado por WebSocket (testing)
  static String websocketPutStatusEndpoint(int id) {
    final ruta = '$websocketBaseUrl/restaurantes/$id/status';
    print('[WSO][RUTA] websocketPutStatusEndpoint: $ruta');
    return ruta;
  }

  // Endpoint para registrar restaurante (dueño)
  static const String registrarRestauranteEndpoint = '/restaurantes';

  static String getRegistrarRestauranteUrl() {
    final ruta = '$apiBaseUrl$registrarRestauranteEndpoint';
    print('[WSO][RUTA] getRegistrarRestauranteUrl: $ruta');
    return ruta;
  }

  static String getApiUrl(String endpoint) {
    final ruta = '$apiBaseUrl$endpoint';
    print('[WSO][RUTA] getApiUrl: $ruta');
    return ruta;
  }

  // Endpoint para actualizar usuario por ID (PUT)
  static String actualizarUsuarioEndpoint(int id) => '/users/$id';

  // Endpoint para actualizar restaurante (dueño)
  static String actualizarRestauranteEndpoint(int id) => '/restaurantes/$id';
}
