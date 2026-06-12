import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/membership_entity.dart';
import '../repositories/memberships_repository.dart';

class GetAllMemberships implements UseCase<List<Membership>, NoParams> {
  final MembershipsRepository repository;

  GetAllMemberships(this.repository);

  @override
  Future<Either<Failure, List<Membership>>> call(NoParams params) async {
    return await repository.getAllMemberships();
  }
}
