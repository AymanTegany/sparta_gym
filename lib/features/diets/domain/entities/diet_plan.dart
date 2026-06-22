import 'package:equatable/equatable.dart';

/// كينونة النظام الغذائي (Diet Plan Entity)
class DietPlan extends Equatable {
  final int? id;
  final String name;        // اسم النظام
  final String? description;// وصف النظام
  final String meals;       // تفاصيل الوجبات
  final String? notes;      // ملاحظات إضافية
  final DateTime createdAt; // تاريخ الإنشاء

  const DietPlan({
    this.id,
    required this.name,
    this.description,
    required this.meals,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        meals,
        notes,
        createdAt,
      ];
}
