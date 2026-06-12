import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/membership_entity.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// واجهة مستودع باقات الاشتراكات (Memberships Repository Interface)
/// ──────────────────────────────────────────────────────────────────────────────
abstract class MembershipsRepository {
  Future<Either<Failure, List<Membership>>> getAllMemberships();
  Future<Either<Failure, int>> addMembership(Membership membership);
  Future<Either<Failure, Unit>> updateMembership(Membership membership);
  Future<Either<Failure, Unit>> deleteMembership(int id);
}
