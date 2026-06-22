import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/trainer_entity.dart';
import '../repositories/trainers_repository.dart';

class AddTrainer implements UseCase<int, Trainer> {
  final TrainersRepository repository;

  AddTrainer(this.repository);

  @override
  Future<Either<Failure, int>> call(Trainer params) async {
    return await repository.addTrainer(params);
  }
}
