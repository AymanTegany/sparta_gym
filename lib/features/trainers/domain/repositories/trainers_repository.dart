import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/trainer_entity.dart';

/// واجهة مستودع المدربين (Trainers Repository Interface)
abstract class TrainersRepository {
  Future<Either<Failure, List<Trainer>>> getAllTrainers();
  Future<Either<Failure, int>> addTrainer(Trainer trainer);
  Future<Either<Failure, Unit>> updateTrainer(Trainer trainer);
  Future<Either<Failure, Unit>> deleteTrainer(int id);
}
