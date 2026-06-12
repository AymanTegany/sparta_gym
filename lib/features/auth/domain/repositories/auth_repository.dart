import 'package:dartz/dartz.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<String, User>> login({
    required String username,
    required String password,
  });

  Future<Either<String, User>> register({
    required String username,
    required String password,
    required String licenseKey,
  });

  Future<Either<String, User>> updateSubscription({
    required int userId,
    required String licenseKey,
  });

  Future<Either<String, User>> checkSession();
  Future<void> logout();
  Future<String> getDeviceId();
}
