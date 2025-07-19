class Product {
  final int id;
  final String name;
  final double price;
  final int? stock;
  final int? categoryId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.stock,
    this.categoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] is String) 
          ? double.tryParse(json['price']) ?? 0.0
          : (json['price'] ?? 0.0).toDouble(),
      stock: json['stock'],
      categoryId: json['categoryId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'price': price,
    };
    
    if (stock != null) data['stock'] = stock;
    if (categoryId != null) data['categoryId'] = categoryId;
    
    return data;
  }
}
