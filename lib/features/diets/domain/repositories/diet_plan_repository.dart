import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/diet_plan.dart';

abstract class DietPlanRepository {
  Future<Either<Failure, List<DietPlan>>> getDietPlans();
  Future<Either<Failure, DietPlan>> getDietPlanById(int id);
  Future<Either<Failure, int>> addDietPlan(DietPlan dietPlan);
  Future<Either<Failure, int>> updateDietPlan(DietPlan dietPlan);
  Future<Either<Failure, int>> deleteDietPlan(int id);
}
