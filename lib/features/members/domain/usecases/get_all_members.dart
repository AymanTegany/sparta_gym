import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/member_entity.dart';
import '../repositories/members_repository.dart';

/// حالة استخدام جلب جميع العملاء
class GetAllMembers extends UseCase<List<Member>, NoParams> {
  final MembersRepository repository;

  GetAllMembers(this.repository);

  @override
  Future<Either<Failure, List<Member>>> call(NoParams params) {
    return repository.getAllMembers();
  }
}
