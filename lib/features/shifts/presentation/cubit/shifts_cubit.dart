import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/shift_report_entity.dart';
import '../../domain/repositories/shifts_repository.dart';
import 'shifts_state.dart';

class ShiftsCubit extends Cubit<ShiftsState> {
  final ShiftsRepository repository;

  /// الشفت النشط حالياً (cached للوصول السريع)
  Shift? _activeShift;
  Shift? get activeShift => _activeShift;

  /// الموظف الحالي
  Employee? _currentEmployee;
  Employee? get currentEmployee => _currentEmployee;

  /// تايمر مراقبة الجدولة التلقائية
  Timer? _schedulerTimer;

  /// لتفادي تشغيل شفت مرتين في نفس الدقيقة
  String? _lastTriggeredKey;

  ShiftsCubit({required this.repository}) : super(ShiftsInitial());

  // ════════════════════════════════════════════════════════════════════════════
  // التحقق من وجود شفت نشط عند بدء التطبيق
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> checkActiveShift() async {
    emit(ShiftsLoading());
    final result = await repository.getActiveShift();
    result.fold(
      (error) => emit(ShiftsError(error)),
      (shift) {
        if (shift != null) {
          _activeShift = shift;
          emit(ShiftsActiveShift(shift));
        } else {
          _loadEmployeesForLogin();
        }
      },
    );
  }

  Future<void> _loadEmployeesForLogin() async {
    final result = await repository.getAllEmployees();
    result.fold(
      (error) => emit(ShiftsNoActiveShift()),
      (employees) {
        // فلترة الموظفين النشطين فقط
        final active = employees.where((e) => e.isActive).toList();
        emit(ShiftsNoActiveShift(employees: active));
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // تسجيل دخول الموظف وبدء الشفت
  // ════════════════════════════════════════════════════════════════════════════

  Future<bool> loginAndStartShift({
    required String name,
    required String password,
  }) async {
    emit(ShiftsLoading());

    // 1. التحقق من بيانات الموظف
    final authResult = await repository.authenticateEmployee(
      name: name,
      password: password,
    );

    return await authResult.fold(
      (error) {
        emit(ShiftsError(error));
        return false;
      },
      (employee) async {
        _currentEmployee = employee;

        // 2. بدء شفت جديد
        final shiftResult = await repository.startShift(
          employeeId: employee.id!,
          employeeName: employee.name,
        );

        return shiftResult.fold(
          (error) {
            emit(ShiftsError(error));
            return false;
          },
          (shift) {
            _activeShift = shift;
            emit(ShiftsActiveShift(shift));
            return true;
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // إنهاء الشفت
  // ════════════════════════════════════════════════════════════════════════════

  Future<ShiftReport?> endCurrentShift() async {
    if (_activeShift == null) return null;

    final shiftId = _activeShift!.id!;
    emit(ShiftsLoading());

    // 1. إنهاء الشفت
    final endResult = await repository.endShift(shiftId);
    return await endResult.fold(
      (error) {
        emit(ShiftsError(error));
        return null;
      },
      (_) async {
        // 2. جلب تقرير الشفت
        final reportResult = await repository.getShiftReport(shiftId);
        return reportResult.fold(
          (error) {
            emit(ShiftsError(error));
            return null;
          },
          (report) {
            _activeShift = null;
            _currentEmployee = null;
            emit(ShiftsEnded(report));
            return report;
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // الإدارة المباشرة للشفتات (بدون تقارير أو كلمات مرور)
  // ════════════════════════════════════════════════════════════════════════════

  Future<bool> startShiftDirectly(Employee employee, {DateTime? customStartTime}) async {
    emit(ShiftsLoading());

    // بدء شفت جديد مباشرة بدون التحقق من الباسورد
    final shiftResult = await repository.startShift(
      employeeId: employee.id!,
      employeeName: employee.name,
      customStartTime: customStartTime,
    );

    return shiftResult.fold(
      (error) {
        emit(ShiftsError(error));
        return false;
      },
      (shift) {
        _activeShift = shift;
        _currentEmployee = employee;
        emit(ShiftsActiveShift(shift));
        return true;
      },
    );
  }

  Future<void> endShiftDirectly() async {
    if (_activeShift == null) return;

    final shiftId = _activeShift!.id!;
    emit(ShiftsLoading());

    // إنهاء الشفت بصمت
    final endResult = await repository.endShift(shiftId);
    endResult.fold(
      (error) => emit(ShiftsError(error)),
      (_) {
        _activeShift = null;
        _currentEmployee = null;
        _loadEmployeesForLogin(); // يعود لحالة عدم وجود شفت
      },
    );
  }

  Future<List<Employee>> fetchEmployeesList() async {
    final result = await repository.getAllEmployees();
    return result.fold(
      (error) => [],
      (employees) => employees,
    );
  }

  Future<ShiftReport?> getLiveShiftReport() async {
    if (_activeShift == null) return null;
    final reportResult = await repository.getShiftReport(_activeShift!.id!);
    return reportResult.fold(
      (error) => null,
      (report) => report,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // العودة لصفحة اختيار الموظف بعد عرض التقرير
  // ════════════════════════════════════════════════════════════════════════════

  void returnToShiftLogin() {
    _activeShift = null;
    _currentEmployee = null;
    _loadEmployeesForLogin();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // إدارة الموظفين (للمدير)
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> loadEmployees() async {
    emit(ShiftsLoading());
    final result = await repository.getAllEmployees();
    result.fold(
      (error) => emit(ShiftsError(error)),
      (employees) => emit(ShiftsEmployeesLoaded(employees)),
    );
  }

  Future<Employee?> addEmployee({
    required String name,
    required String password,
    String role = 'employee',
  }) async {
    final result = await repository.addEmployee(
      name: name,
      password: password,
      role: role,
    );
    return result.fold(
      (error) {
        emit(ShiftsError(error));
        return null;
      },
      (employee) {
        emit(const ShiftsEmployeeActionSuccess('تم إضافة الموظف بنجاح'));
        return employee;
      },
    );
  }

  Future<bool> updateEmployee(Employee employee, {String? newPassword}) async {
    final result = await repository.updateEmployee(employee, newPassword: newPassword);
    return result.fold(
      (error) {
        emit(ShiftsError(error));
        return false;
      },
      (_) {
        emit(const ShiftsEmployeeActionSuccess('تم تعديل بيانات الموظف بنجاح'));
        return true;
      },
    );
  }

  Future<bool> deleteEmployee(int id) async {
    final result = await repository.deleteEmployee(id);
    return result.fold(
      (error) {
        emit(ShiftsError(error));
        return false;
      },
      (_) {
        emit(const ShiftsEmployeeActionSuccess('تم حذف الموظف بنجاح'));
        return true;
      },
    );
  }

  /// الحصول على shiftId الحالي لاستخدامه في العمليات
  int? get currentShiftId => _activeShift?.id;

  // ════════════════════════════════════════════════════════════════════════════
  // جدولة الشفتات التلقائية
  // ════════════════════════════════════════════════════════════════════════════

  /// بدء مراقبة الجدولة - يتم استدعاؤها عند بدء التطبيق
  void startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkScheduledShifts();
    });
    // فحص فوري عند البدء
    _checkScheduledShifts();
  }

  /// فحص الشفتات المجدولة وتشغيل/إنهاء المطابق للوقت الحالي
  Future<void> _checkScheduledShifts() async {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    final result = await repository.getEnabledScheduledShifts();
    final schedules = result.fold((_) => <Map<String, dynamic>>[], (data) => data);
    if (schedules.isEmpty) return;

    // ── 1. لو في شفت نشط → تحقق هل حان وقت إنهائه ──
    if (_activeShift != null) {
      for (final schedule in schedules) {
        final endHour = schedule['endHour'] as int?;
        final endMinute = schedule['endMinute'] as int?;
        if (endHour == null || endMinute == null) continue;

        final employeeId = schedule['employeeId'] as int;
        if (_activeShift!.employeeId == employeeId) {
          final endKey = 'end-${now.year}-${now.month}-${now.day}-$endHour-$endMinute';
          if (currentHour == endHour && currentMinute == endMinute && _lastTriggeredKey != endKey) {
            _lastTriggeredKey = endKey;
            await endShiftDirectly();
            return;
          }
        }
      }
      return; // في شفت نشط ولم يحن وقت إنهائه
    }

    // ── 2. لا يوجد شفت نشط → تحقق هل حان وقت بدء شفت ──
    for (final schedule in schedules) {
      final hour = schedule['startHour'] as int;
      final minute = schedule['startMinute'] as int;

      // مفتاح فريد لتفادي التكرار في نفس الدقيقة
      final key = 'start-${now.year}-${now.month}-${now.day}-$hour-$minute';

      if (currentHour == hour && currentMinute == minute && _lastTriggeredKey != key) {
        _lastTriggeredKey = key;

        final employeeId = schedule['employeeId'] as int;
        final employeeName = schedule['employeeName'] as String;

        final employee = Employee(
          id: employeeId,
          name: employeeName,
        );

        final customTime = DateTime(
          now.year, now.month, now.day, hour, minute,
        );

        await startShiftDirectly(employee, customStartTime: customTime);
        return; // شفت واحد فقط في المرة
      }
    }
  }

  /// إضافة شفت مجدول جديد
  Future<bool> addScheduledShift({
    required int employeeId,
    required String employeeName,
    required int startHour,
    required int startMinute,
    int? endHour,
    int? endMinute,
  }) async {
    final result = await repository.addScheduledShift(
      employeeId: employeeId,
      employeeName: employeeName,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
    );
    return result.fold((_) => false, (_) => true);
  }

  /// حذف شفت مجدول
  Future<bool> deleteScheduledShift(int id) async {
    final result = await repository.deleteScheduledShift(id);
    return result.fold((_) => false, (_) => true);
  }

  /// جلب الشفتات المجدولة
  Future<List<Map<String, dynamic>>> getScheduledShifts() async {
    final result = await repository.getEnabledScheduledShifts();
    return result.fold((_) => [], (data) => data);
  }

  @override
  Future<void> close() {
    _schedulerTimer?.cancel();
    return super.close();
  }
}
