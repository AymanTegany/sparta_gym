import 'package:dartz/dartz.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/shift_report_entity.dart';
import '../../domain/repositories/shifts_repository.dart';
import '../datasources/shifts_local_data_source.dart';
import '../models/employee_model.dart';

class ShiftsRepositoryImpl implements ShiftsRepository {
  final ShiftsLocalDataSource localDataSource;

  ShiftsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<String, List<Employee>>> getAllEmployees() async {
    try {
      final employees = await localDataSource.getAllEmployees();
      return Right(employees);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, Employee>> addEmployee({
    required String name,
    required String password,
    String role = 'employee',
  }) async {
    try {
      final employee = await localDataSource.addEmployee(
        name: name,
        password: password,
        role: role,
      );
      return Right(employee);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> updateEmployee(Employee employee, {String? newPassword}) async {
    try {
      await localDataSource.updateEmployee(
        EmployeeModel.fromEntity(employee),
        newPassword: newPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> deleteEmployee(int id) async {
    try {
      await localDataSource.deleteEmployee(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, Employee>> authenticateEmployee({
    required String name,
    required String password,
  }) async {
    try {
      final employee = await localDataSource.authenticateEmployee(
        name: name,
        password: password,
      );
      return Right(employee);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, Shift>> startShift({required int employeeId, required String employeeName, DateTime? customStartTime}) async {
    try {
      final shift = await localDataSource.startShift(employeeId: employeeId, employeeName: employeeName, customStartTime: customStartTime);
      return Right(shift);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> endShift(int shiftId) async {
    try {
      await localDataSource.endShift(shiftId);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, Shift?>> getActiveShift() async {
    try {
      final shift = await localDataSource.getActiveShift();
      return Right(shift);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, ShiftReport>> getShiftReport(int shiftId) async {
    try {
      final report = await localDataSource.getShiftReport(shiftId);
      return Right(report);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, List<Shift>>> getShiftHistory({int? employeeId, int limit = 50}) async {
    try {
      final shifts = await localDataSource.getShiftHistory(employeeId: employeeId, limit: limit);
      return Right(shifts);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // جدولة الشفتات التلقائية
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<String, void>> addScheduledShift({
    required int employeeId,
    required String employeeName,
    required int startHour,
    required int startMinute,
    int? endHour,
    int? endMinute,
  }) async {
    try {
      await localDataSource.addScheduledShift(
        employeeId: employeeId,
        employeeName: employeeName,
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, List<Map<String, dynamic>>>> getEnabledScheduledShifts() async {
    try {
      final result = await localDataSource.getEnabledScheduledShifts();
      return Right(result);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> deleteScheduledShift(int id) async {
    try {
      await localDataSource.deleteScheduledShift(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
