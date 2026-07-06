import 'package:equatable/equatable.dart';

/// كيان تقرير نهاية الشفت
class ShiftReport extends Equatable {
  /// معلومات الشفت الأساسية
  final int shiftId;
  final String employeeName;
  final DateTime startTime;
  final DateTime endTime;

  /// الإيرادات
  final double newSubscriptionsRevenue;   // إيرادات الاشتراكات الجديدة
  final double renewalsRevenue;           // إيرادات التجديدات
  final double otherPaymentsRevenue;      // مدفوعات أخرى
  final double inventorySalesRevenue;     // إيرادات مبيعات المخزون

  /// المصروفات
  final double totalExpenses;

  /// الأعداد
  final int newMembersCount;              // عدد الأعضاء الجدد
  final int renewalsCount;                // عدد التجديدات
  final int totalAttendance;              // عدد الحضور
  final int totalPaymentsCount;           // عدد عمليات الدفع
  final int totalSalesCount;              // عدد عمليات البيع

  const ShiftReport({
    required this.shiftId,
    required this.employeeName,
    required this.startTime,
    required this.endTime,
    this.newSubscriptionsRevenue = 0,
    this.renewalsRevenue = 0,
    this.otherPaymentsRevenue = 0,
    this.inventorySalesRevenue = 0,
    this.totalExpenses = 0,
    this.newMembersCount = 0,
    this.renewalsCount = 0,
    this.totalAttendance = 0,
    this.totalPaymentsCount = 0,
    this.totalSalesCount = 0,
  });

  /// إجمالي الإيرادات
  double get totalRevenue =>
      newSubscriptionsRevenue +
      renewalsRevenue +
      otherPaymentsRevenue +
      inventorySalesRevenue;

  /// صافي الربح (الإيرادات - المصروفات)
  double get netProfit => totalRevenue - totalExpenses;

  /// مدة الشفت بالدقائق
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// مدة الشفت كنص مقروء
  String get durationText {
    final mins = durationMinutes;
    final hours = mins ~/ 60;
    final remaining = mins % 60;
    if (hours > 0) {
      return '$hours ساعة و $remaining دقيقة';
    }
    return '$remaining دقيقة';
  }

  @override
  List<Object?> get props => [
        shiftId,
        employeeName,
        startTime,
        endTime,
        newSubscriptionsRevenue,
        renewalsRevenue,
        otherPaymentsRevenue,
        inventorySalesRevenue,
        totalExpenses,
        newMembersCount,
        renewalsCount,
        totalAttendance,
        totalPaymentsCount,
        totalSalesCount,
      ];
}
