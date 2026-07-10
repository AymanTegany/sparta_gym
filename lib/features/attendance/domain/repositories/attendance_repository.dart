import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/attendance_entity.dart';

/// واجهة مستودع الحضور والانصراف (Attendance Repository Interface)
abstract class AttendanceRepository {
  /// تسجيل دخول عضو باستخدام الباركود أو رقم الهاتف
  Future<Either<Failure, Attendance>> checkInMember(String barcodeOrPhone);

  /// تسجيل خروج عضو باستخدام الباركود أو رقم الهاتف
  Future<Either<Failure, Attendance>> checkOutMember(String barcodeOrPhone);

  /// جلب سجل الحضور ليوم محدد (بصيغة YYYY-MM-DD)
  Future<Either<Failure, List<Attendance>>> getDailyAttendance(String dateStr);

  /// جلب إحصائيات الحضور
  Future<Either<Failure, Map<String, dynamic>>> getAttendanceStats();
  Future<Either<Failure, void>> autoCheckoutOutdatedAttendances(int maxHours);
  Future<Either<Failure, bool>> isMemberCheckedIn(String barcodeOrPhone);
  Future<Either<Failure, List<Attendance>>> getMemberAttendance(String memberId);
}
