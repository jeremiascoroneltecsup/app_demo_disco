class Table {
  final int id;
  final int tableNumber;
  final int floorNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Table({
    required this.id,
    required this.tableNumber,
    required this.floorNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Table.fromJson(Map<String, dynamic> json) {
    return Table(
      id: json['id'],
      tableNumber: json['tableNumber'],
      floorNumber: json['floorNumber'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'floorNumber': floorNumber,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
