import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/trainer_entity.dart';
import '../repositories/trainers_repository.dart';

class UpdateTrainer implements UseCase<Unit, Trainer> {
  final TrainersRepository repository;

  UpdateTrainer(this.repository);

  @override
  Future<Either<Failure, Unit>> call(Trainer params) async {
    return await repository.updateTrainer(params);
  }
}
