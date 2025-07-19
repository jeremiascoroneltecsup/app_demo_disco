import 'product.dart';

class PromotionDetail {
  final int id;
  final int promotionId;
  final int productId;
  final int quantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Product? product;

  PromotionDetail({
    required this.id,
    required this.promotionId,
    required this.productId,
    required this.quantity,
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  factory PromotionDetail.fromJson(Map<String, dynamic> json) {
    return PromotionDetail(
      id: json['id'] ?? 0,
      promotionId: json['promotionId'] ?? 0,
      productId: json['productId'] ?? 0,
      quantity: json['quantity'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      product: json['Product'] != null 
          ? Product.fromJson(json['Product']) 
          : null,
    );
  }
}

class Promotion {
  final int id;
  final String name;
  final double price;
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<PromotionDetail> promotionDetails;

  Promotion({
    required this.id,
    required this.name,
    required this.price,
    required this.enabled,
    this.createdAt,
    this.updatedAt,
    required this.promotionDetails,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    var detailsList = json['PromotionDetails'] as List? ?? [];
    List<PromotionDetail> details = detailsList
        .map((detail) => PromotionDetail.fromJson(detail))
        .toList();

    return Promotion(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] is String) 
          ? double.tryParse(json['price']) ?? 0.0
          : (json['price'] ?? 0.0).toDouble(),
      enabled: json['enabled'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      promotionDetails: details,
    );
  }

  int get totalProducts {
    return promotionDetails.fold(0, (sum, detail) => sum + detail.quantity);
  }
}
