import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/membership_entity.dart';
import '../repositories/memberships_repository.dart';

class AddMembership implements UseCase<int, Membership> {
  final MembershipsRepository repository;

  AddMembership(this.repository);

  @override
  Future<Either<Failure, int>> call(Membership params) async {
    return await repository.addMembership(params);
  }
}
