import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/home_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final HomeRepository repository;

  DashboardCubit({required this.repository}) : super(DashboardInitial());

  /// تحميل إحصائيات لوحة التحكم
  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    final result = await repository.getDashboardStats();
    result.fold(
      (failure) => emit(DashboardError(message: failure.message)),
      (stats) => emit(DashboardLoaded(stats: stats)),
    );
  }
}
