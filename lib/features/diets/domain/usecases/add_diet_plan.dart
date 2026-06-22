import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/diet_plan.dart';
import '../repositories/diet_plan_repository.dart';

class AddDietPlan implements UseCase<int, DietPlan> {
  final DietPlanRepository repository;

  AddDietPlan(this.repository);

  @override
  Future<Either<Failure, int>> call(DietPlan params) async {
    return await repository.addDietPlan(params);
  }
}
