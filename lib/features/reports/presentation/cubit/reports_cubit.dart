import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/reports_repository.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportsRepository repository;

  ReportsCubit({required this.repository}) : super(ReportsInitial());

  Future<void> loadReports(DateTime startDate, DateTime endDate) async {
    emit(ReportsLoading());
    final result = await repository.getReportStats(startDate, endDate);
    result.fold(
      (failure) => emit(ReportsError(message: failure.message)),
      (stats) => emit(ReportsLoaded(stats: stats, startDate: startDate, endDate: endDate)),
    );
  }

  Future<void> loadComprehensiveReports(DateTime startDate, DateTime endDate) async {
    emit(ReportsLoading());
    final result = await repository.getComprehensiveReport(startDate, endDate);
    result.fold(
      (failure) => emit(ReportsError(message: failure.message)),
      (stats) => emit(ComprehensiveReportsLoaded(stats: stats, startDate: startDate, endDate: endDate)),
    );
  }
}
