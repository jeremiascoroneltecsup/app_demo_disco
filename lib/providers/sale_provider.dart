import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/product.dart';
import '../models/promotion.dart';
import '../models/table.dart';
import '../models/payment_type.dart';
import '../models/sale.dart';
import '../services/api_service.dart';

class SaleProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Cart _cart = Cart();
  
  Table? _selectedTable;
  PaymentType? _selectedPaymentType;
  double _tip = 0.0;
  bool _isProcessing = false;

  // Getters
  Cart get cart => _cart;
  Table? get selectedTable => _selectedTable;
  PaymentType? get selectedPaymentType => _selectedPaymentType;
  double get tip => _tip;
  bool get isProcessing => _isProcessing;

  double get subtotal => _cart.subtotal;
  double get total => subtotal + _tip;

  // Setters
  void setSelectedTable(Table table) {
    _selectedTable = table;
    notifyListeners();
  }

  void setSelectedPaymentType(PaymentType paymentType) {
    _selectedPaymentType = paymentType;
    notifyListeners();
  }

  void setTip(double tip) {
    _tip = tip;
    notifyListeners();
  }

  // Cart operations
  void addProductToCart(Product product, {int quantity = 1}) {
    if (product.stock >= quantity) {
      _cart.addProduct(product, quantity: quantity);
      notifyListeners();
    }
  }

  void addPromotionToCart(Promotion promotion, {int quantity = 1}) {
    _cart.addPromotion(promotion, quantity: quantity);
    notifyListeners();
  }

  void updateCartItemQuantity(CartItem item, int quantity) {
    // Verificar stock para productos
    if (item.type == CartItemType.product && item.product != null) {
      if (quantity > item.product!.stock) {
        return; // No permitir más que el stock disponible
      }
    }
    
    _cart.updateQuantity(item, quantity);
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _cart.removeItem(item);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // Process sale
  Future<bool> processSale() async {
    if (_selectedTable == null || _selectedPaymentType == null || _cart.isEmpty) {
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final products = _cart.items
          .where((item) => item.type == CartItemType.product)
          .map((item) => SaleProduct(
                productId: item.id,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
              ))
          .toList();

      final promotions = _cart.items
          .where((item) => item.type == CartItemType.promotion)
          .map((item) => SalePromotion(
                promotionId: item.id,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
              ))
          .toList();

      final saleRequest = CreateSaleRequest(
        tableId: _selectedTable!.id,
        paymentTypeId: _selectedPaymentType!.id,
        subtotal: subtotal,
        tip: _tip,
        total: total,
        products: products,
        promotions: promotions,
      );

      final success = await _apiService.createSale(saleRequest);
      
      if (success) {
        // Reset sale state
        _cart.clear();
        _selectedTable = null;
        _selectedPaymentType = null;
        _tip = 0.0;
      }

      _isProcessing = false;
      notifyListeners();
      
      return success;
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  // Reset sale process
  void resetSale() {
    _cart.clear();
    _selectedTable = null;
    _selectedPaymentType = null;
    _tip = 0.0;
    _isProcessing = false;
    notifyListeners();
  }
}
