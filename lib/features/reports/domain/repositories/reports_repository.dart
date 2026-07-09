import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/report_stats.dart';
import '../entities/comprehensive_report_data.dart';

abstract class ReportsRepository {
  Future<Either<Failure, ReportStats>> getReportStats(DateTime startDate, DateTime endDate);
  Future<Either<Failure, ComprehensiveReportData>> getComprehensiveReport(DateTime startDate, DateTime endDate);
}
