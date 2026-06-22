import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/trainer_entity.dart';
import '../repositories/trainers_repository.dart';

class GetAllTrainers implements UseCase<List<Trainer>, NoParams> {
  final TrainersRepository repository;

  GetAllTrainers(this.repository);

  @override
  Future<Either<Failure, List<Trainer>>> call(NoParams params) async {
    return await repository.getAllTrainers();
  }
}
