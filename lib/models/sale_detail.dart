import 'product.dart';
import 'promotion.dart';

class SaleProductDetail {
  final int id;
  final int saleId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Product? product;

  SaleProductDetail({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  factory SaleProductDetail.fromJson(Map<String, dynamic> json) {
    return SaleProductDetail(
      id: json['id'],
      saleId: json['saleId'],
      productId: json['productId'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] is String) 
          ? double.parse(json['unitPrice']) 
          : json['unitPrice'].toDouble(),
      subtotal: (json['subtotal'] is String) 
          ? double.parse(json['subtotal']) 
          : json['subtotal'].toDouble(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      product: json['Product'] != null ? Product.fromJson(json['Product']) : null,
    );
  }
}

class SalePromotionDetail {
  final int id;
  final int saleId;
  final int promotionId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Promotion? promotion;

  SalePromotionDetail({
    required this.id,
    required this.saleId,
    required this.promotionId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.createdAt,
    this.updatedAt,
    this.promotion,
  });

  factory SalePromotionDetail.fromJson(Map<String, dynamic> json) {
    return SalePromotionDetail(
      id: json['id'],
      saleId: json['saleId'],
      promotionId: json['promotionId'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] is String) 
          ? double.parse(json['unitPrice']) 
          : json['unitPrice'].toDouble(),
      subtotal: (json['subtotal'] is String) 
          ? double.parse(json['subtotal']) 
          : json['subtotal'].toDouble(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      promotion: json['Promotion'] != null ? Promotion.fromJson(json['Promotion']) : null,
    );
  }
}

// Clase unificada para mostrar en la UI
class SaleItemDetail {
  final String itemName;
  final String itemType; // "Producto" o "Promoción"
  final int quantity;
  final double unitPrice;
  final double subtotal;

  SaleItemDetail({
    required this.itemName,
    required this.itemType,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItemDetail.fromProductDetail(SaleProductDetail productDetail) {
    return SaleItemDetail(
      itemName: productDetail.product?.name ?? 'Producto desconocido',
      itemType: 'Producto',
      quantity: productDetail.quantity,
      unitPrice: productDetail.unitPrice,
      subtotal: productDetail.subtotal,
    );
  }

  factory SaleItemDetail.fromPromotionDetail(SalePromotionDetail promotionDetail) {
    return SaleItemDetail(
      itemName: promotionDetail.promotion?.name ?? 'Promoción desconocida',
      itemType: 'Promoción',
      quantity: promotionDetail.quantity,
      unitPrice: promotionDetail.unitPrice,
      subtotal: promotionDetail.subtotal,
    );
  }
}
