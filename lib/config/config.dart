// lib/config/config.dart
class AppConfig {
  static const String apiBaseUrl = 'http://192.168.100.9:8081/FoodMaps_API/public/api';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';

  // Endpoints para clientes
  static const String restaurantesClienteEndpoint = '/clientes/restaurantes';
  static String restauranteClienteDetalleEndpoint(int id) => '/clientes/restaurantes/$id';

  // Endpoint para cambiar estado restaurante (dueño)
  static String restauranteChangeStatusEndpoint(int id) => '/restaurantes/$id/change-status';

  // Endpoint para obtener el estado actual del restaurante (dueño)
  static String restauranteStatusEndpoint(int id) => '/restaurantes/$id/status';

  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';
}