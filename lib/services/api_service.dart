import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/product.dart';
import '../models/promotion.dart';
import '../models/payment_type.dart';
import '../models/table.dart';
import '../models/sale.dart';
import '../models/sale_with_details.dart';
import '../models/category.dart';
import '../utils/api_config.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Login
  Future<LoginResponse> login(String username, String password) async {
    try {
      print('DEBUG: Intentando login con usuario: $username');
      print('DEBUG: URL: ${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
      final body = jsonEncode({
        'username': username,
        'password': password,
      });
      
      print('DEBUG: Body: $body');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: body,
      ).timeout(const Duration(seconds: 10)); // Reducido de 30 a 10 segundos

      print('DEBUG: Status Code: ${response.statusCode}');
      print('DEBUG: Response Body: ${response.body}');

      if (response.body.isEmpty) {
        return LoginResponse(
          success: false,
          error: 'El servidor no respondió correctamente',
        );
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(data);
        if (loginResponse.token != null) {
          setToken(loginResponse.token!);
        }
        return loginResponse;
      } else {
        return LoginResponse(
          success: false,
          error: data['message'] ?? 'Credenciales incorrectas (${response.statusCode})',
        );
      }
    } on TimeoutException {
      return LoginResponse(
        success: false,
        error: 'Timeout: El servidor tardó demasiado en responder',
      );
    } on SocketException {
      return LoginResponse(
        success: false,
        error: 'Error de conexión: Verifica tu conexión a internet',
      );
    } on FormatException {
      return LoginResponse(
        success: false,
        error: 'Error: Respuesta del servidor inválida',
      );
    } catch (e) {
      print('DEBUG: Error inesperado: $e');
      return LoginResponse(
        success: false,
        error: 'Error de conexión: $e',
      );
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.currentUserEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get all users
  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> usersJson = data['data'];
          return usersJson.map((json) => User.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // Get categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categoriesEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> categoriesJson = data['data'];
          return categoriesJson.map((json) => Category.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Get products
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> productsJson = data['data'];
          return productsJson.map((json) => Product.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  // Get promotions
  Future<List<Promotion>> getPromotions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.promotionsEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> promotionsJson = data['data'];
          return promotionsJson.map((json) {
            try {
              return Promotion.fromJson(json);
            } catch (e) {
              print('Warning: Error parsing promotion, skipping: $e');
              return null;
            }
          }).where((promotion) => promotion != null).cast<Promotion>().toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting promotions: $e');
      return [];
    }
  }

  // Get payment types
  Future<List<PaymentType>> getPaymentTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.paymentTypesEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> paymentTypesJson = data['data'];
          return paymentTypesJson.map((json) => PaymentType.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting payment types: $e');
      return [];
    }
  }

  // Get tables
  Future<List<Table>> getTables() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tablesEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> tablesJson = data['data'];
          return tablesJson.map((json) => Table.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting tables: $e');
      return [];
    }
  }

  // Get sales
  Future<List<Sale>> getSales() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> salesJson = data['data'];
          return salesJson.map((json) => Sale.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting sales: $e');
      return [];
    }
  }

  // Get promotion with full details
  Future<Promotion?> getPromotionDetails(int promotionId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.promotionsEndpoint}/$promotionId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Promotion.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting promotion details: $e');
      return null;
    }
  }

  // Get sale with details (products and promotions)
  Future<SaleWithDetails?> getSaleWithDetails(int saleId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}/$saleId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SaleWithDetails.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting sale details: $e');
      return null;
    }
  }

  // Create sale
  Future<bool> createSale(CreateSaleRequest saleRequest) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.salesEndpoint}'),
        headers: _headers,
        body: jsonEncode(saleRequest.toJson()),
      ).timeout(const Duration(seconds: 12)); // Un poco más de tiempo para crear venta

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error creating sale: $e');
      return false;
    }
  }
}
