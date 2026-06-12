import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/dashboard_stats.dart';

/// واجهة مستودع لوحة التحكم (Home Repository)
abstract class HomeRepository {
  /// جلب كافة الإحصائيات والمعلومات الخاصة بلوحة التحكم
  Future<Either<Failure, DashboardStats>> getDashboardStats();
}
