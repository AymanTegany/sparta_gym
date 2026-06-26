import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/report_stats.dart';

abstract class ReportsRepository {
  Future<Either<Failure, ReportStats>> getReportStats(DateTime startDate, DateTime endDate);
}
