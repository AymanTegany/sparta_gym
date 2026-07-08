import 'package:dartz/dartz.dart';
import '../entities/employee_entity.dart';
import '../entities/shift_entity.dart';
import '../entities/shift_report_entity.dart';

abstract class ShiftsRepository {
  // ─── إدارة الموظفين ───
  Future<Either<String, List<Employee>>> getAllEmployees();
  Future<Either<String, Employee>> addEmployee({required String name, required String password, String role = 'employee'});
  Future<Either<String, void>> updateEmployee(Employee employee, {String? newPassword});
  Future<Either<String, void>> deleteEmployee(int id);
  Future<Either<String, Employee>> authenticateEmployee({required String name, required String password});

  // ─── إدارة الشفتات ───
  Future<Either<String, Shift>> startShift({required int employeeId, required String employeeName, DateTime? customStartTime});
  Future<Either<String, void>> endShift(int shiftId);
  Future<Either<String, Shift?>> getActiveShift();
  Future<Either<String, ShiftReport>> getShiftReport(int shiftId);
  Future<Either<String, List<Shift>>> getShiftHistory({int? employeeId, int limit = 50});

  // ─── جدولة الشفتات التلقائية ───
  Future<Either<String, void>> addScheduledShift({required int employeeId, required String employeeName, required int startHour, required int startMinute, int? endHour, int? endMinute, int isEnabled = 1});
  Future<Either<String, List<Map<String, dynamic>>>> getEnabledScheduledShifts();
  Future<Either<String, void>> deleteScheduledShift(int id);
}
