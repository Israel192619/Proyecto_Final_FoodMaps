// lib/config/config.dart
class AppConfig {
  static const String apiBaseUrl = 'http://192.168.100.9:8081/FoodMaps_API/public/api';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/register';
  // Agrega aquí otros endpoints si los necesitas

  static String getApiUrl(String endpoint) => '$apiBaseUrl$endpoint';
}