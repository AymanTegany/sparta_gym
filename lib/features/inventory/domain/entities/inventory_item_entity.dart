class InventoryItem {
  final int? id;
  final String name;
  final String category; // المكملات الغذائية, المشروبات, الأدوات الرياضية
  final double price;
  final double cost;
  final int quantity;
  final String? barcode;
  final String createdAt;

  InventoryItem({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    this.cost = 0,
    required this.quantity,
    this.barcode,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'cost': cost,
      'quantity': quantity,
      'barcode': barcode,
      'createdAt': createdAt,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      price: map['price'],
      cost: map['cost'] ?? 0,
      quantity: map['quantity'],
      barcode: map['barcode'],
      createdAt: map['createdAt'],
    );
  }
}
