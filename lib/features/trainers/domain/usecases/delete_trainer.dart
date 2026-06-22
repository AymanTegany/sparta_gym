import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/trainers_repository.dart';

class DeleteTrainer implements UseCase<Unit, int> {
  final TrainersRepository repository;

  DeleteTrainer(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int params) async {
    return await repository.deleteTrainer(params);
  }
}
