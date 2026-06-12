import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/member_entity.dart';
import '../repositories/members_repository.dart';

/// حالة استخدام إضافة عميل جديد
class AddMember extends UseCase<int, Member> {
  final MembersRepository repository;

  AddMember(this.repository);

  @override
  Future<Either<Failure, int>> call(Member params) {
    return repository.addMember(params);
  }
}
