import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<String, User>> call({
    required String username,
    required String password,
    required String licenseKey,
  }) async {
    return await repository.register(
      username:   username,
      password:   password,
      licenseKey: licenseKey,
    );
  }
}
