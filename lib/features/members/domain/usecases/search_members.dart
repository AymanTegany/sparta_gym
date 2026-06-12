import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/member_entity.dart';
import '../repositories/members_repository.dart';

/// حالة استخدام البحث في العملاء
class SearchMembers extends UseCase<List<Member>, String> {
  final MembersRepository repository;

  SearchMembers(this.repository);

  @override
  Future<Either<Failure, List<Member>>> call(String params) {
    return repository.searchMembers(params);
  }
}
