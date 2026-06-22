class PosSaleItem {
  final int? id;
  final int saleId;
  final int itemId;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  PosSaleItem({
    this.id,
    required this.saleId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'itemId': itemId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
    };
  }

  factory PosSaleItem.fromMap(Map<String, dynamic> map) {
    return PosSaleItem(
      id: map['id'],
      saleId: map['saleId'],
      itemId: map['itemId'],
      quantity: map['quantity'],
      unitPrice: map['unitPrice'],
      subtotal: map['subtotal'],
    );
  }
}
