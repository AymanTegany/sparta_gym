import '../../domain/entities/report_stats.dart';

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

class ReportsError extends ReportsState {
  final String message;
  ReportsError({required this.message});
}
