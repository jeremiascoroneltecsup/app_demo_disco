import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as models;
import '../models/promotion.dart';
import '../models/payment_type.dart';
import '../models/table.dart';
import '../models/sale.dart';
import '../services/api_service.dart';

class DataProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  List<models.Category> _categories = [];
  List<Promotion> _promotions = [];
  List<PaymentType> _paymentTypes = [];
  List<Table> _tables = [];
  List<Sale> _sales = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Product> get products => _products;
  List<models.Category> get categories => _categories;
  List<Promotion> get promotions => _promotions;
  List<PaymentType> get paymentTypes => _paymentTypes;
  List<Table> get tables => _tables;
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get filtered products by category
  List<Product> getProductsByCategory(int? categoryId) {
    if (categoryId == null) return _products;
    return _products.where((product) => product.categoryId == categoryId).toList();
  }

  // Get products with stock
  List<Product> get availableProducts => _products.where((product) => product.stock > 0).toList();

  // Get active promotions
  List<Promotion> get activePromotions => _promotions.where((promotion) => promotion.enabled).toList();

  // Get tables by floor
  List<Table> getTablesByFloor(int floor) {
    return _tables.where((table) => table.floorNumber == floor).toList();
  }

  // Get floors
  List<int> get floors {
    final floorsSet = _tables.map((table) => table.floorNumber).toSet();
    final floorsList = floorsSet.toList();
    floorsList.sort();
    return floorsList;
  }

  // Sales statistics
  double get todayTotalSales {
    final today = DateTime.now();
    final todaySales = _sales.where((sale) {
      return sale.saleDate.year == today.year &&
             sale.saleDate.month == today.month &&
             sale.saleDate.day == today.day;
    });
    return todaySales.fold(0.0, (sum, sale) => sum + sale.total);
  }

  int get todayOrdersCount {
    final today = DateTime.now();
    return _sales.where((sale) {
      return sale.saleDate.year == today.year &&
             sale.saleDate.month == today.month &&
             sale.saleDate.day == today.day;
    }).length;
  }

  double get totalTips {
    return _sales.fold(0.0, (sum, sale) => sum + sale.tip);
  }

  double get averageTip {
    if (_sales.isEmpty) return 0.0;
    return totalTips / _sales.length;
  }

  // Load all data
  Future<void> loadAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        loadProducts(),
        loadCategories(),
        loadPromotions(),
        loadPaymentTypes(),
        loadTables(),
        loadSales(),
      ]);
    } catch (e) {
      _errorMessage = 'Error loading data: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load individual data
  Future<void> loadProducts() async {
    try {
      _products = await _apiService.getProducts();
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.getCategories();
      notifyListeners();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> loadPromotions() async {
    try {
      _promotions = await _apiService.getPromotions();
      notifyListeners();
    } catch (e) {
      print('Error loading promotions: $e');
    }
  }

  Future<void> loadPaymentTypes() async {
    try {
      _paymentTypes = await _apiService.getPaymentTypes();
      notifyListeners();
    } catch (e) {
      print('Error loading payment types: $e');
    }
  }

  Future<void> loadTables() async {
    try {
      _tables = await _apiService.getTables();
      notifyListeners();
    } catch (e) {
      print('Error loading tables: $e');
    }
  }

  Future<void> loadSales() async {
    try {
      _sales = await _apiService.getSales();
      // Sort sales by date (most recent first)
      _sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      notifyListeners();
    } catch (e) {
      print('Error loading sales: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
