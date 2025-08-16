// lib/config/config.dart
class AppConfig {
  static const String apiBaseUrl = 'http://192.168.100.9:8081/FoodMaps_API/public/api';

    // NUEVO: Ruta base pública para imágenes de productos y menús
  static const String storageBaseUrl = 'http://192.168.100.9:8081/FoodMaps_API/storage/app/public/';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';

  // Endpoints para clientes
  static const String restaurantesClienteEndpoint = '/clientes/restaurantes';
  static String restauranteClienteDetalleEndpoint(int id) => '/clientes/restaurantes/$id';

  // Endpoint para obtener productos de un menú específico de un restaurante (clientes)
  static String productosMenuRestauranteEndpoint(int restauranteId, int menuId) =>
      '/clientes/restaurantes/$restauranteId/menus/$menuId/productos';

  // Endpoint para cambiar estado restaurante (dueño)
  static String restauranteChangeStatusEndpoint(int id) => '/restaurantes/$id/change-status';

  // Endpoint para obtener el estado actual del restaurante (dueño)
  static String restauranteStatusEndpoint(int id) => '/restaurantes/$id/status';

  // --- WebSocket para estados en tiempo real ---
  static const String websocketBaseUrl = 'ws://192.168.100.9:9000';
  static const String websocketFullUrl = 'ws://192.168.100.9:9000/app/f70zdychxrkeuixgvhwz?protocol=7&client=js&version=7.0.3&flash=false';

  static String getWebSocketUrl() => websocketFullUrl;

  // Endpoint para escuchar eventos de estado en tiempo real
  static String websocketEventsEndpoint() => '$websocketBaseUrl/events';

  // Endpoint para actualizar estado por WebSocket (testing)
  static String websocketPutStatusEndpoint(int id) => '$websocketBaseUrl/restaurantes/$id/status';

  // Endpoint para registrar restaurante (dueño)
  static const String registrarRestauranteEndpoint = '/restaurantes';

  static String getRegistrarRestauranteUrl() => '$apiBaseUrl$registrarRestauranteEndpoint';

  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';

  // Endpoint para actualizar usuario por ID (PUT)
  static String actualizarUsuarioEndpoint(int id) => '/users/$id';

  // Endpoint para actualizar restaurante (dueño)
  static String actualizarRestauranteEndpoint(int id) => '/restaurantes/$id';

  // Endpoint para eliminar restaurante (dueño)
  static String eliminarRestauranteEndpoint(int id) => '/restaurantes/$id';
}
