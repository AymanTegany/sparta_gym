import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/members_repository.dart';
import '../datasources/members_local_data_source.dart';
import '../models/member_model.dart';

/// تنفيذ الـ Repository لإدارة العملاء.
/// يتعامل مع مصدر البيانات المحلي ويحول الاستثناءات إلى Failures.
class MembersRepositoryImpl implements MembersRepository {
  final MembersLocalDataSource localDataSource;

  MembersRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Member>>> getAllMembers() async {
    try {
      final members = await localDataSource.getAllMembers();
      return Right(members);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, Member>> getMemberById(int id) async {
    try {
      final member = await localDataSource.getMemberById(id);
      return Right(member);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> addMember(Member member) async {
    try {
      final model = MemberModel.fromEntity(member);
      final id = await localDataSource.addMember(model);
      return Right(id);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMember(Member member) async {
    try {
      final model = MemberModel.fromEntity(member);
      await localDataSource.updateMember(model);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMember(int id) async {
    try {
      await localDataSource.deleteMember(id);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Member>>> searchMembers(String query) async {
    try {
      final members = await localDataSource.searchMembers(query);
      return Right(members);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطأ غير متوقع: $e'));
    }
  }
}
