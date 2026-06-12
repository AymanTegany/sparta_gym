import 'package:equatable/equatable.dart';

/// كيان المدفوعات (Payment Entity)
class Payment extends Equatable {
  final int? id;
  final String receiptId;
  final String memberId;
  final String? memberName; // يُسترجع عبر JOIN للتيسير في العرض
  final String? memberPhone; // يُسترجع عبر JOIN للتيسير في العرض
  final double amount;
  final String paymentMethod; // نقدي، فودافون كاش، إنستاباي، تحويل بنكي، بطاقة
  final String paymentDate;
  final String employeeName; // اسم الموظف المسؤول
  final String? notes;

  const Payment({
    this.id,
    required this.receiptId,
    required this.memberId,
    this.memberName,
    this.memberPhone,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.employeeName,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id,
        receiptId,
        memberId,
        memberName,
        memberPhone,
        amount,
        paymentMethod,
        paymentDate,
        employeeName,
        notes,
      ];
}
