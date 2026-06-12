import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/membership_entity.dart';
import '../../domain/repositories/memberships_repository.dart';
import '../datasources/memberships_local_data_source.dart';
import '../models/membership_model.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// تنفيذ مستودع باقات الاشتراكات (Memberships Repository Implementation)
/// ──────────────────────────────────────────────────────────────────────────────
class MembershipsRepositoryImpl implements MembershipsRepository {
  final MembershipsLocalDataSource localDataSource;

  MembershipsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Membership>>> getAllMemberships() async {
    try {
      final models = await localDataSource.getAllMemberships();
      return Right(models);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> addMembership(Membership membership) async {
    try {
      final model = MembershipModel.fromEntity(membership);
      final id = await localDataSource.addMembership(model);
      return Right(id);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMembership(Membership membership) async {
    try {
      final model = MembershipModel.fromEntity(membership);
      await localDataSource.updateMembership(model);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMembership(int id) async {
    try {
      await localDataSource.deleteMembership(id);
      return const Right(unit);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
