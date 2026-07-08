import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/employee_model.dart';
import '../models/shift_model.dart';
import '../../domain/entities/shift_report_entity.dart';

abstract class ShiftsLocalDataSource {
  // ─── إدارة الموظفين ───
  Future<List<EmployeeModel>> getAllEmployees();
  Future<EmployeeModel> addEmployee({required String name, required String password, String role = 'employee'});
  Future<void> updateEmployee(EmployeeModel employee, {String? newPassword});
  Future<void> deleteEmployee(int id);
  Future<EmployeeModel> authenticateEmployee({required String name, required String password});

  // ─── إدارة الشفتات ───
  Future<ShiftModel> startShift({required int employeeId, required String employeeName, DateTime? customStartTime});
  Future<void> endShift(int shiftId);
  Future<ShiftModel?> getActiveShift();
  Future<ShiftReport> getShiftReport(int shiftId);
  Future<List<ShiftModel>> getShiftHistory({int? employeeId, int limit = 50});

  // ─── جدولة الشفتات التلقائية ───
  Future<void> addScheduledShift({required int employeeId, required String employeeName, required int startHour, required int startMinute, int? endHour, int? endMinute, int isEnabled = 1});
  Future<List<Map<String, dynamic>>> getEnabledScheduledShifts();
  Future<void> deleteScheduledShift(int id);
}

class ShiftsLocalDataSourceImpl implements ShiftsLocalDataSource {
  final DatabaseHelper databaseHelper;

  ShiftsLocalDataSourceImpl({required this.databaseHelper});

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // إدارة الموظفين
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Future<List<EmployeeModel>> getAllEmployees() async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query('employees', orderBy: 'id ASC');
      return results.map((map) => EmployeeModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب قائمة الموظفين: $e');
    }
  }

  @override
  Future<EmployeeModel> addEmployee({
    required String name,
    required String password,
    String role = 'employee',
  }) async {
    try {
      final db = await databaseHelper.database;

      // التحقق من عدم تكرار الاسم
      final existing = await db.query(
        'employees',
        where: 'name = ?',
        whereArgs: [name],
      );
      if (existing.isNotEmpty) {
        throw const DatabaseException('اسم الموظف موجود مسبقاً');
      }

      final id = await db.insert('employees', {
        'name': name,
        'password': _hashPassword(password),
        'role': role,
        'isActive': 1,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return EmployeeModel(
        id: id,
        name: name,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
      );
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('فشل في إضافة الموظف: $e');
    }
  }

  @override
  Future<void> updateEmployee(EmployeeModel employee, {String? newPassword}) async {
    try {
      final db = await databaseHelper.database;
      final updateData = <String, dynamic>{
        'name': employee.name,
        'role': employee.role,
        'isActive': employee.isActive ? 1 : 0,
      };
      if (newPassword != null && newPassword.isNotEmpty) {
        updateData['password'] = _hashPassword(newPassword);
      }
      await db.update(
        'employees',
        updateData,
        where: 'id = ?',
        whereArgs: [employee.id],
      );
    } catch (e) {
      throw DatabaseException('فشل في تعديل بيانات الموظف: $e');
    }
  }

  @override
  Future<void> deleteEmployee(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete('employees', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('فشل في حذف الموظف: $e');
    }
  }

  @override
  Future<EmployeeModel> authenticateEmployee({
    required String name,
    required String password,
  }) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'employees',
        where: 'name = ? AND password = ? AND isActive = 1',
        whereArgs: [name, _hashPassword(password)],
      );

      if (results.isEmpty) {
        throw const DatabaseException('اسم الموظف أو كلمة المرور غير صحيحة');
      }

      return EmployeeModel.fromMap(results.first);
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('فشل في تسجيل دخول الموظف: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // إدارة الشفتات
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Future<ShiftModel> startShift({
    required int employeeId,
    required String employeeName,
    DateTime? customStartTime,
  }) async {
    try {
      final db = await databaseHelper.database;

      // إنهاء أي شفت نشط سابق
      await db.update(
        'shifts',
        {
          'isActive': 0,
          'endTime': DateTime.now().toIso8601String(),
        },
        where: 'isActive = 1',
      );

      final now = DateTime.now();
      final startTime = customStartTime ?? now;
      final id = await db.insert('shifts', {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'startTime': startTime.toIso8601String(),
        'isActive': 1,
      });

      return ShiftModel(
        id: id,
        employeeId: employeeId,
        employeeName: employeeName,
        startTime: startTime,
        isActive: true,
      );
    } catch (e) {
      throw DatabaseException('فشل في بدء الشفت: $e');
    }
  }

  @override
  Future<void> endShift(int shiftId) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        'shifts',
        {
          'isActive': 0,
          'endTime': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [shiftId],
      );
    } catch (e) {
      throw DatabaseException('فشل في إنهاء الشفت: $e');
    }
  }

  @override
  Future<ShiftModel?> getActiveShift() async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'shifts',
        where: 'isActive = 1',
        limit: 1,
      );
      if (results.isEmpty) return null;
      return ShiftModel.fromMap(results.first);
    } catch (e) {
      throw DatabaseException('فشل في جلب الشفت النشط: $e');
    }
  }

  @override
  Future<ShiftReport> getShiftReport(int shiftId) async {
    try {
      final db = await databaseHelper.database;

      // جلب بيانات الشفت
      final shiftResults = await db.query(
        'shifts',
        where: 'id = ?',
        whereArgs: [shiftId],
      );
      if (shiftResults.isEmpty) {
        throw const DatabaseException('الشفت غير موجود');
      }
      final shift = ShiftModel.fromMap(shiftResults.first);
      final startStr = shift.startTime.toIso8601String();
      final endStr = (shift.endTime ?? DateTime.now()).toIso8601String();

      // 1. إيرادات الاشتراكات الجديدة
      final newSubsResult = await db.rawQuery(
        '''SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as count
           FROM payments
           WHERE shiftId = ? AND notes LIKE ?''',
        [shiftId, '%دفعة أولى%'],
      );
      final newSubscriptionsRevenue = (newSubsResult.first['total'] as num).toDouble();
      final newSubsCount = newSubsResult.first['count'] as int;

      // 2. إيرادات التجديدات
      final renewalsResult = await db.rawQuery(
        '''SELECT COALESCE(SUM(amount), 0) as total, COUNT(*) as count
           FROM payments
           WHERE shiftId = ? AND notes LIKE ?''',
        [shiftId, '%تجديد%'],
      );
      final renewalsRevenue = (renewalsResult.first['total'] as num).toDouble();
      final renewalsCount = renewalsResult.first['count'] as int;

      // 3. مدفوعات أخرى
      final otherResult = await db.rawQuery(
        '''SELECT COALESCE(SUM(amount), 0) as total
           FROM payments
           WHERE shiftId = ? AND notes NOT LIKE ? AND notes NOT LIKE ?''',
        [shiftId, '%دفعة أولى%', '%تجديد%'],
      );
      final otherPaymentsRevenue = (otherResult.first['total'] as num).toDouble();

      // 4. إجمالي عمليات الدفع
      final totalPaymentsResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM payments WHERE shiftId = ?',
        [shiftId],
      );
      final totalPaymentsCount = totalPaymentsResult.first['count'] as int;

      // 5. مبيعات المخزون
      final inventoryResult = await db.rawQuery(
        '''SELECT COALESCE(SUM(finalAmount), 0) as total, COUNT(*) as count
           FROM pos_sales
           WHERE shiftId = ?''',
        [shiftId],
      );
      final inventorySalesRevenue = (inventoryResult.first['total'] as num).toDouble();
      final totalSalesCount = inventoryResult.first['count'] as int;

      // 6. المصروفات
      final expensesResult = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE shiftId = ?',
        [shiftId],
      );
      final totalExpenses = (expensesResult.first['total'] as num).toDouble();

      // 7. الحضور أثناء الشفت (بالوقت وليس بالـ shiftId)
      final attendanceResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM attendance WHERE checkInTime >= ? AND checkInTime <= ?',
        [startStr, endStr],
      );
      final totalAttendance = attendanceResult.first['count'] as int;

      // 8. أعضاء جدد أثناء الشفت (بالوقت)
      final newMembersResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM members WHERE createdAt >= ? AND createdAt <= ?',
        [startStr, endStr],
      );
      final newMembersCount = newMembersResult.first['count'] as int;

      return ShiftReport(
        shiftId: shiftId,
        employeeName: shift.employeeName,
        startTime: shift.startTime,
        endTime: shift.endTime ?? DateTime.now(),
        newSubscriptionsRevenue: newSubscriptionsRevenue,
        renewalsRevenue: renewalsRevenue,
        otherPaymentsRevenue: otherPaymentsRevenue,
        inventorySalesRevenue: inventorySalesRevenue,
        totalExpenses: totalExpenses,
        newMembersCount: newMembersCount,
        renewalsCount: renewalsCount,
        totalAttendance: totalAttendance,
        totalPaymentsCount: totalPaymentsCount,
        totalSalesCount: totalSalesCount,
      );
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('فشل في جلب تقرير الشفت: $e');
    }
  }

  @override
  Future<List<ShiftModel>> getShiftHistory({int? employeeId, int limit = 50}) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.query(
        'shifts',
        where: employeeId != null ? 'employeeId = ?' : null,
        whereArgs: employeeId != null ? [employeeId] : null,
        orderBy: 'id DESC',
        limit: limit,
      );
      return results.map((map) => ShiftModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب سجل الشفتات: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // جدولة الشفتات التلقائية
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Future<void> addScheduledShift({
    required int employeeId,
    required String employeeName,
    required int startHour,
    required int startMinute,
    int? endHour,
    int? endMinute,
    int isEnabled = 1,
  }) async {
    try {
      final db = await databaseHelper.database;
      await db.insert('scheduled_shifts', {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'isEnabled': isEnabled,
      });
    } catch (e) {
      throw DatabaseException('فشل في إضافة جدولة الشفت: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getEnabledScheduledShifts() async {
    try {
      final db = await databaseHelper.database;
      return await db.query(
        'scheduled_shifts',
      );
    } catch (e) {
      throw DatabaseException('فشل في جلب الشفتات المجدولة: $e');
    }
  }

  @override
  Future<void> deleteScheduledShift(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete('scheduled_shifts', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw DatabaseException('فشل في حذف الشفت المجدول: $e');
    }
  }
}
