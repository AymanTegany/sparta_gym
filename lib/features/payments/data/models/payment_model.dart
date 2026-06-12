import '../../domain/entities/payment_entity.dart';

/// نموذج عملية الدفع (Payment Model)
class PaymentModel extends Payment {
  const PaymentModel({
    super.id,
    required super.receiptId,
    required super.memberId,
    super.memberName,
    super.memberPhone,
    required super.amount,
    required super.paymentMethod,
    required super.paymentDate,
    required super.employeeName,
    super.notes,
  });

  /// التحويل من SQLite Map
  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as int?,
      receiptId: map['receiptId'] as String,
      memberId: map['memberId'] as String,
      memberName: map['fullName'] as String?, // ينتج عن دمج (JOIN) جدول الأعضاء
      memberPhone: map['phoneNumber'] as String?, // ينتج عن دمج (JOIN) جدول الأعضاء
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String,
      paymentDate: map['paymentDate'] as String,
      employeeName: map['employeeName'] as String,
      notes: map['notes'] as String?,
    );
  }

  /// التحويل إلى SQLite Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'receiptId': receiptId,
      'memberId': memberId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'employeeName': employeeName,
      'notes': notes,
    };
  }

  /// التحويل من Entity
  factory PaymentModel.fromEntity(Payment entity) {
    return PaymentModel(
      id: entity.id,
      receiptId: entity.receiptId,
      memberId: entity.memberId,
      memberName: entity.memberName,
      memberPhone: entity.memberPhone,
      amount: entity.amount,
      paymentMethod: entity.paymentMethod,
      paymentDate: entity.paymentDate,
      employeeName: entity.employeeName,
      notes: entity.notes,
    );
  }
}
