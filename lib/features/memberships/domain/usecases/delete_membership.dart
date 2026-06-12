import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/memberships_repository.dart';

class DeleteMembership implements UseCase<Unit, int> {
  final MembershipsRepository repository;

  DeleteMembership(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int params) async {
    return await repository.deleteMembership(params);
  }
}
