import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/diet_plan.dart';
import '../repositories/diet_plan_repository.dart';

class GetDietPlans implements UseCase<List<DietPlan>, NoParams> {
  final DietPlanRepository repository;

  GetDietPlans(this.repository);

  @override
  Future<Either<Failure, List<DietPlan>>> call(NoParams params) async {
    return await repository.getDietPlans();
  }
}
