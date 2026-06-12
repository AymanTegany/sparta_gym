import 'package:equatable/equatable.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// كينونة باقة الاشتراك (Membership Entity)
/// ──────────────────────────────────────────────────────────────────────────────
class Membership extends Equatable {
  final int? id;
  final String name;          // اسم الباقة
  final int durationDays;     // مدة الاشتراك بالأيام
  final double price;         // السعر
  final int freezeDays;       // عدد أيام التجميد المسموح بها
  final int? visitsLimit;     // عدد الزيارات (null يعني باقة غير محدودة)
  final bool isActive;        // حالة الباقة (نشطة / موقوفة)
  final String createdAt;     // تاريخ الإنشاء

  const Membership({
    this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.freezeDays,
    this.visitsLimit,
    required this.isActive,
    required this.createdAt,
  });

  /// هل الباقة محدودة بعدد زيارات؟
  bool get isLimitedVisits => visitsLimit != null;

  @override
  List<Object?> get props => [
        id,
        name,
        durationDays,
        price,
        freezeDays,
        visitsLimit,
        isActive,
        createdAt,
      ];
}
