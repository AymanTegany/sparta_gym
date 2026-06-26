import 'package:equatable/equatable.dart';

/// كينونة المدرب (Trainer Entity)
class Trainer extends Equatable {
  final int? id;
  final String fullName;        // اسم المدرب
  final String phoneNumber;     // رقم الهاتف
  final String? specialization; // التخصص (لياقة، كمال أجسام، كارديو، إلخ)
  final double? price;         // السعر
  final String? workingHours;   // ساعات العمل
  final String? notes;          // ملاحظات
  final bool isActive;          // حالة المدرب (نشط / غير نشط)
  final String createdAt;       // تاريخ الإضافة

  const Trainer({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    this.specialization,
    this.price,
    this.workingHours,
    this.notes,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        fullName,
        phoneNumber,
        specialization,
        price,
        workingHours,
        notes,
        isActive,
        createdAt,
      ];
}
