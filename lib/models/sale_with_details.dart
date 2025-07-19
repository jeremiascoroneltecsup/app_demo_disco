import 'sale.dart';
import 'sale_detail.dart';
import 'user.dart';
import 'table.dart';
import 'payment_type.dart';

class SaleWithDetails extends Sale {
  final List<SaleProductDetail> saleProductDetails;
  final List<SalePromotionDetail> salePromotionDetails;

  SaleWithDetails({
    required super.id,
    required super.userId,
    required super.tableId,
    required super.paymentTypeId,
    required super.subtotal,
    required super.tip,
    required super.total,
    required super.saleDate,
    super.createdAt,
    super.updatedAt,
    super.user,
    super.table,
    super.paymentType,
    required this.saleProductDetails,
    required this.salePromotionDetails,
  });

  factory SaleWithDetails.fromJson(Map<String, dynamic> json) {
    // Parse product details
    List<SaleProductDetail> productDetails = [];
    if (json['SaleProductDetails'] != null) {
      productDetails = (json['SaleProductDetails'] as List)
          .map((item) => SaleProductDetail.fromJson(item))
          .toList();
    }

    // Parse promotion details
    List<SalePromotionDetail> promotionDetails = [];
    if (json['SalePromotionDetails'] != null) {
      promotionDetails = (json['SalePromotionDetails'] as List)
          .map((item) => SalePromotionDetail.fromJson(item))
          .toList();
    }

    return SaleWithDetails(
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
      paymentType: json['PaymentType'] != null ? PaymentType.fromJson(json['PaymentType']) : null,
      saleProductDetails: productDetails,
      salePromotionDetails: promotionDetails,
    );
  }

  // Método para obtener todos los artículos como una lista unificada
  List<SaleItemDetail> getAllItems() {
    List<SaleItemDetail> allItems = [];
    
    // Agregar productos
    for (var productDetail in saleProductDetails) {
      allItems.add(SaleItemDetail.fromProductDetail(productDetail));
    }
    
    // Agregar promociones
    for (var promotionDetail in salePromotionDetails) {
      allItems.add(SaleItemDetail.fromPromotionDetail(promotionDetail));
    }
    
    return allItems;
  }

  // Método para verificar si tiene artículos
  bool get hasItems => saleProductDetails.isNotEmpty || salePromotionDetails.isNotEmpty;
}
