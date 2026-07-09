import '../../domain/entities/report_stats.dart';
import '../../domain/entities/comprehensive_report_data.dart';

abstract class ReportsState {}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final ReportStats stats;
  final DateTime startDate;
  final DateTime endDate;

  ReportsLoaded({
    required this.stats,
    required this.startDate,
    required this.endDate,
  });
}

class ComprehensiveReportsLoaded extends ReportsState {
  final ComprehensiveReportData stats;
  final DateTime startDate;
  final DateTime endDate;

  ComprehensiveReportsLoaded({
    required this.stats,
    required this.startDate,
    required this.endDate,
  });
}

class ReportsError extends ReportsState {
  final String message;
  ReportsError({required this.message});
}
