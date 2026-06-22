import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/diet_plan.dart';
import '../../domain/usecases/add_diet_plan.dart';
import '../../domain/usecases/delete_diet_plan.dart';
import '../../domain/usecases/get_diet_plans.dart';
import '../../domain/usecases/update_diet_plan.dart';
import 'diet_plans_state.dart';

class DietPlansCubit extends Cubit<DietPlansState> {
  final GetDietPlans _getDietPlans;
  final AddDietPlan _addDietPlan;
  final UpdateDietPlan _updateDietPlan;
  final DeleteDietPlan _deleteDietPlan;

  DietPlansCubit({
    required GetDietPlans getDietPlans,
    required AddDietPlan addDietPlan,
    required UpdateDietPlan updateDietPlan,
    required DeleteDietPlan deleteDietPlan,
  })  : _getDietPlans = getDietPlans,
        _addDietPlan = addDietPlan,
        _updateDietPlan = updateDietPlan,
        _deleteDietPlan = deleteDietPlan,
        super(DietPlansInitial());

  Future<void> fetchDietPlans() async {
    emit(DietPlansLoading());
    final result = await _getDietPlans(NoParams());
    result.fold(
      (failure) => emit(DietPlansError(failure.message)),
      (dietPlans) => emit(DietPlansLoaded(dietPlans)),
    );
  }

  Future<void> addDietPlan(DietPlan dietPlan) async {
    emit(DietPlansLoading());
    final result = await _addDietPlan(dietPlan);
    result.fold(
      (failure) => emit(DietPlansError(failure.message)),
      (_) {
        emit(const DietPlanOperationSuccess('تمت إضافة النظام الغذائي بنجاح'));
        fetchDietPlans();
      },
    );
  }

  Future<void> updateDietPlan(DietPlan dietPlan) async {
    emit(DietPlansLoading());
    final result = await _updateDietPlan(dietPlan);
    result.fold(
      (failure) => emit(DietPlansError(failure.message)),
      (_) {
        emit(const DietPlanOperationSuccess('تم تحديث النظام الغذائي بنجاح'));
        fetchDietPlans();
      },
    );
  }

  Future<void> deleteDietPlan(int id) async {
    emit(DietPlansLoading());
    final result = await _deleteDietPlan(id);
    result.fold(
      (failure) => emit(DietPlansError(failure.message)),
      (_) {
        emit(const DietPlanOperationSuccess('تم حذف النظام الغذائي بنجاح'));
        fetchDietPlans();
      },
    );
  }
}
