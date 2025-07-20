class ApiConfig {
  // URL del API de producción
  static const String baseUrl = 'https://api-demo-43yz.onrender.com/api';
  
  // Configuraciones optimizadas para mejor rendimiento
  static const int connectionTimeout = 10000; // Reducido a 10 segundos
  static const int receiveTimeout = 10000; // Reducido a 10 segundos
  
  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Connection': 'close', // Cerrar conexiones para liberar recursos
  };
  
  // Endpoints
  static const String loginEndpoint = '/users/login';
  static const String usersEndpoint = '/users';
  static const String currentUserEndpoint = '/users/me';
  static const String categoriesEndpoint = '/categories';
  static const String productsEndpoint = '/products';
  static const String promotionsEndpoint = '/promotions';
  static const String paymentTypesEndpoint = '/payment-types';
  static const String tablesEndpoint = '/tables';
  static const String salesEndpoint = '/sales';
}

// Credenciales de prueba (SOLO PARA DESARROLLO)
class TestCredentials {
  static const String username = 'user';
  static const String password = '123456';
}
