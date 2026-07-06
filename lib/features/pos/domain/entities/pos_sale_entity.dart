class PosSale {
  final int? id;
  final String receiptId;
  final double totalAmount;
  final double discount;
  final double finalAmount;
  final String paymentMethod;
  final String? memberId;
  final String date;
  final String createdAt;
  final int? shiftId;

  PosSale({
    this.id,
    required this.receiptId,
    required this.totalAmount,
    this.discount = 0,
    required this.finalAmount,
    required this.paymentMethod,
    this.memberId,
    required this.date,
    required this.createdAt,
    this.shiftId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receiptId': receiptId,
      'totalAmount': totalAmount,
      'discount': discount,
      'finalAmount': finalAmount,
      'paymentMethod': paymentMethod,
      'memberId': memberId,
      'date': date,
      'createdAt': createdAt,
      if (shiftId != null) 'shiftId': shiftId,
    };
  }

  factory PosSale.fromMap(Map<String, dynamic> map) {
    return PosSale(
      id: map['id'],
      receiptId: map['receiptId'],
      totalAmount: map['totalAmount'],
      discount: map['discount'] ?? 0,
      finalAmount: map['finalAmount'],
      paymentMethod: map['paymentMethod'],
      memberId: map['memberId'],
      date: map['date'],
      createdAt: map['createdAt'],
      shiftId: map['shiftId'],
    );
  }
}
