import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/member_entity.dart';
import '../repositories/members_repository.dart';

/// حالة استخدام تحديث بيانات عميل
class UpdateMember extends UseCase<Unit, Member> {
  final MembersRepository repository;

  UpdateMember(this.repository);

  @override
  Future<Either<Failure, Unit>> call(Member params) {
    return repository.updateMember(params);
  }
}
