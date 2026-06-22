import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/diet_plan.dart';
import '../../domain/repositories/diet_plan_repository.dart';
import '../datasources/diet_plan_local_data_source.dart';
import '../models/diet_plan_model.dart';

class DietPlanRepositoryImpl implements DietPlanRepository {
  final DietPlanLocalDataSource localDataSource;

  DietPlanRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, int>> addDietPlan(DietPlan dietPlan) async {
    try {
      final id = await localDataSource.addDietPlan(DietPlanModel.fromEntity(dietPlan));
      return Right(id);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> deleteDietPlan(int id) async {
    try {
      final result = await localDataSource.deleteDietPlan(id);
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DietPlan>> getDietPlanById(int id) async {
    try {
      final dietPlan = await localDataSource.getDietPlanById(id);
      return Right(dietPlan);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DietPlan>>> getDietPlans() async {
    try {
      final dietPlans = await localDataSource.getDietPlans();
      return Right(dietPlans);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> updateDietPlan(DietPlan dietPlan) async {
    try {
      final result = await localDataSource.updateDietPlan(DietPlanModel.fromEntity(dietPlan));
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
