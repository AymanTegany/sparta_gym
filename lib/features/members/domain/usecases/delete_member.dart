import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/members_repository.dart';

/// حالة استخدام حذف عميل
class DeleteMember extends UseCase<Unit, int> {
  final MembersRepository repository;

  DeleteMember(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int params) {
    return repository.deleteMember(params);
  }
}
