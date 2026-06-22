import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/trainer_entity.dart';
import '../../domain/repositories/trainers_repository.dart';
import '../datasources/trainers_local_data_source.dart';
import '../models/trainer_model.dart';

/// تنفيذ مستودع المدربين (Trainers Repository Implementation)
class TrainersRepositoryImpl implements TrainersRepository {
  final TrainersLocalDataSource localDataSource;

  TrainersRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Trainer>>> getAllTrainers() async {
    try {
      final models = await localDataSource.getAllTrainers();
      return Right(models);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> addTrainer(Trainer trainer) async {
    try {
      final model = TrainerModel.fromEntity(trainer);
      final id = await localDataSource.addTrainer(model);
      return Right(id);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTrainer(Trainer trainer) async {
    try {
      final model = TrainerModel.fromEntity(trainer);
      await localDataSource.updateTrainer(model);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTrainer(int id) async {
    try {
      await localDataSource.deleteTrainer(id);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
