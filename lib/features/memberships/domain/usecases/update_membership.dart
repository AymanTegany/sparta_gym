import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/membership_entity.dart';
import '../repositories/memberships_repository.dart';

class UpdateMembership implements UseCase<Unit, Membership> {
  final MembershipsRepository repository;

  UpdateMembership(this.repository);

  @override
  Future<Either<Failure, Unit>> call(Membership params) async {
    return await repository.updateMembership(params);
  }
}
