class Product {
  final int id;
  final String name;
  final double price;
  final int stock;
  final int categoryId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: (json['price'] is String) 
          ? double.parse(json['price']) 
          : json['price'].toDouble(),
      stock: json['stock'],
      categoryId: json['categoryId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
    };
  }
}
