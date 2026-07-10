import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_data_source.dart';

/// تطبيق مستودع الحضور والانصراف (Attendance Repository Implementation)
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource localDataSource;

  AttendanceRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Attendance>> checkInMember(String barcodeOrPhone) async {
    try {
      final attendance = await localDataSource.checkInMember(barcodeOrPhone);
      return Right(attendance);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في تسجيل الحضور: $e'));
    }
  }

  @override
  Future<Either<Failure, Attendance>> checkOutMember(String barcodeOrPhone) async {
    try {
      final attendance = await localDataSource.checkOutMember(barcodeOrPhone);
      return Right(attendance);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في تسجيل الانصراف: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getDailyAttendance(String dateStr) async {
    try {
      final list = await localDataSource.getDailyAttendance(dateStr);
      return Right(list);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في جلب الحضور اليومي: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAttendanceStats() async {
    try {
      final stats = await localDataSource.getAttendanceStats();
      return Right(stats);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في جلب إحصائيات الحضور: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> autoCheckoutOutdatedAttendances(int maxHours) async {
    try {
      await localDataSource.autoCheckoutOutdatedAttendances(maxHours);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في إنهاء الجلسات المعلقة: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isMemberCheckedIn(String barcodeOrPhone) async {
    try {
      final result = await localDataSource.isMemberCheckedIn(barcodeOrPhone);
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في التحقق من حالة حضور العضو: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getMemberAttendance(String memberId) async {
    try {
      final result = await localDataSource.getMemberAttendance(memberId);
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في جلب سجل حضور العضو: $e'));
    }
  }
}
