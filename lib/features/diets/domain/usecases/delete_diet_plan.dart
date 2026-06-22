import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/diet_plan_repository.dart';

class DeleteDietPlan implements UseCase<int, int> {
  final DietPlanRepository repository;

  DeleteDietPlan(this.repository);

  @override
  Future<Either<Failure, int>> call(int params) async {
    return await repository.deleteDietPlan(params);
  }
}
