import 'package:dartz/dartz.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final LocalAuthDataSource localDataSource;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<String, User>> login({
    required String username,
    required String password,
  }) async {
    try {
      final user = await localDataSource.login(username: username, password: password);
      return Right(user);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, User>> register({
    required String username,
    required String password,
    required String licenseKey,
  }) async {
    try {
      final user = await localDataSource.register(
        username:   username,
        password:   password,
        licenseKey: licenseKey,
      );
      return Right(user);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, User>> updateSubscription({
    required int userId,
    required String licenseKey,
  }) async {
    try {
      final user = await localDataSource.updateSubscription(
        userId:     userId,
        licenseKey: licenseKey,
      );
      return Right(user);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, User>> checkSession() async {
    try {
      final user = await localDataSource.checkSession();
      if (user != null) return Right(user);
      return const Left('لا توجد جلسة نشطة');
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<void> logout() async => await localDataSource.logout();

  @override
  Future<String> getDeviceId() async => localDataSource.getDeviceId();
}
