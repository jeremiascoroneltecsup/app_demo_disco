import 'product.dart';
import 'promotion.dart';

enum CartItemType { product, promotion }

class CartItem {
  final int id;
  final CartItemType type;
  final String name;
  final double unitPrice;
  int quantity;
  final Product? product;
  final Promotion? promotion;

  CartItem({
    required this.id,
    required this.type,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.product,
    this.promotion,
  });

  double get subtotal => unitPrice * quantity;

  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      id: product.id,
      type: CartItemType.product,
      name: product.name,
      unitPrice: product.price,
      quantity: quantity,
      product: product,
    );
  }

  factory CartItem.fromPromotion(Promotion promotion, {int quantity = 1}) {
    return CartItem(
      id: promotion.id,
      type: CartItemType.promotion,
      name: promotion.name,
      unitPrice: promotion.price,
      quantity: quantity,
      promotion: promotion,
    );
  }
}

class Cart {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  void addProduct(Product product, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.type == CartItemType.product && item.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem.fromProduct(product, quantity: quantity));
    }
  }

  void addPromotion(Promotion promotion, {int quantity = 1}) {
    final existingIndex = _items.indexWhere(
      (item) => item.type == CartItemType.promotion && item.id == promotion.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem.fromPromotion(promotion, quantity: quantity));
    }
  }

  void updateQuantity(CartItem item, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(item);
    } else {
      final index = _items.indexOf(item);
      if (index >= 0) {
        _items[index].quantity = newQuantity;
      }
    }
  }

  void removeItem(CartItem item) {
    _items.remove(item);
  }

  void clear() {
    _items.clear();
  }
}
