import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/member_entity.dart';
import '../repositories/members_repository.dart';

/// حالة استخدام جلب عميل بالمعرف
class GetMemberById extends UseCase<Member, int> {
  final MembersRepository repository;

  GetMemberById(this.repository);

  @override
  Future<Either<Failure, Member>> call(int params) {
    return repository.getMemberById(params);
  }
}
