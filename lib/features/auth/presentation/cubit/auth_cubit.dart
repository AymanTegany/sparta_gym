import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sparta_gym/features/auth/domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit(this.repository) : super(AuthInitial());

  Future<void> checkSession() async {
    emit(AuthLoading());
    final result = await repository.checkSession();
    result.fold(
      (error) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(AuthLoading());
    final result = await repository.login(
      username: username,
      password: password,
    );
    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> register({
    required String username,
    required String password,
    required String licenseKey,
  }) async {
    emit(AuthLoading());
    final result = await repository.register(
      username: username,
      password: password,
      licenseKey: licenseKey,
    );
    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(AuthRegistered(user.username)),
    );
  }

  /// تحديث الاشتراك للمستخدم الحالي.
  Future<void> updateSubscription({
    required int userId,
    required String licenseKey,
  }) async {
    final result = await repository.updateSubscription(
      userId: userId,
      licenseKey: licenseKey,
    );

    result.fold(
      (error) => emit(AuthError(error)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> logout() async {
    await repository.logout();
    emit(AuthUnauthenticated());
  }

  Future<String> getDeviceId() async => await repository.getDeviceId();
}
