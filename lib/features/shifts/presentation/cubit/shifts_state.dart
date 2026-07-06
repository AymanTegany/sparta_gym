import 'package:equatable/equatable.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/shift_report_entity.dart';

/// حالات نظام الشفتات
abstract class ShiftsState extends Equatable {
  const ShiftsState();
  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class ShiftsInitial extends ShiftsState {}

/// جاري التحميل
class ShiftsLoading extends ShiftsState {}

/// لا يوجد شفت نشط - يحتاج الموظف لتسجيل الدخول
class ShiftsNoActiveShift extends ShiftsState {
  final List<Employee> employees;
  const ShiftsNoActiveShift({this.employees = const []});

  @override
  List<Object?> get props => [employees];
}

/// شفت نشط حالياً
class ShiftsActiveShift extends ShiftsState {
  final Shift shift;
  const ShiftsActiveShift(this.shift);

  @override
  List<Object?> get props => [shift];
}

/// تم إنهاء الشفت - عرض التقرير
class ShiftsEnded extends ShiftsState {
  final ShiftReport report;
  const ShiftsEnded(this.report);

  @override
  List<Object?> get props => [report];
}

/// خطأ
class ShiftsError extends ShiftsState {
  final String message;
  const ShiftsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// حالة إدارة الموظفين
class ShiftsEmployeesLoaded extends ShiftsState {
  final List<Employee> employees;
  const ShiftsEmployeesLoaded(this.employees);

  @override
  List<Object?> get props => [employees];
}

/// تم إضافة/تعديل/حذف موظف بنجاح
class ShiftsEmployeeActionSuccess extends ShiftsState {
  final String message;
  const ShiftsEmployeeActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
