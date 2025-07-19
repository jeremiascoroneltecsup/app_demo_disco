import 'user.dart';
import 'table.dart';
import 'payment_type.dart';

class Sale {
  final int id;
  final int userId;
  final int tableId;
  final int paymentTypeId;
  final double subtotal;
  final double tip;
  final double total;
  final DateTime saleDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final User? user;
  final Table? table;
  final PaymentType? paymentType;

  Sale({
    required this.id,
    required this.userId,
    required this.tableId,
    required this.paymentTypeId,
    required this.subtotal,
    required this.tip,
    required this.total,
    required this.saleDate,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.table,
    this.paymentType,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      userId: json['userId'],
      tableId: json['tableId'],
      paymentTypeId: json['paymentTypeId'],
      subtotal: (json['subtotal'] is String) 
          ? double.parse(json['subtotal']) 
          : json['subtotal'].toDouble(),
      tip: (json['tip'] is String) 
          ? double.parse(json['tip']) 
          : json['tip'].toDouble(),
      total: (json['total'] is String) 
          ? double.parse(json['total']) 
          : json['total'].toDouble(),
      saleDate: DateTime.parse(json['saleDate']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      user: json['User'] != null ? User.fromJson(json['User']) : null,
      table: json['Table'] != null ? Table.fromJson(json['Table']) : null,
      paymentType: json['PaymentType'] != null 
          ? PaymentType.fromJson(json['PaymentType']) 
          : null,
    );
  }
}

// Para crear nuevas ventas
class SaleProduct {
  final int productId;
  final int quantity;
  final double unitPrice;

  SaleProduct({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class SalePromotion {
  final int promotionId;
  final int quantity;
  final double unitPrice;

  SalePromotion({
    required this.promotionId,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'promotionId': promotionId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

class CreateSaleRequest {
  final int tableId;
  final int paymentTypeId;
  final double subtotal;
  final double tip;
  final double total;
  final List<SaleProduct> products;
  final List<SalePromotion> promotions;

  CreateSaleRequest({
    required this.tableId,
    required this.paymentTypeId,
    required this.subtotal,
    required this.tip,
    required this.total,
    this.products = const [],
    this.promotions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'tableId': tableId,
      'paymentTypeId': paymentTypeId,
      'subtotal': subtotal,
      'tip': tip,
      'total': total,
      if (products.isNotEmpty) 'products': products.map((p) => p.toJson()).toList(),
      if (promotions.isNotEmpty) 'promotions': promotions.map((p) => p.toJson()).toList(),
    };
  }
}
