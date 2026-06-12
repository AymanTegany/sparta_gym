/// طبقة: Presentation (Bloc / Cubit)
/// مسؤول عن إدارة حالة واجهة المستخدم (State Management) والتواصل مع الـ Usecases.
/// 
/// ملف: auth_bloc.dart
/// يستقبل الأحداث (Events) من الـ UI، ينفذ الـ Usecase المناسب، ثم يصدر حالة (State) جديدة للـ UI.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/usecases/user_login.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc({required this.loginUseCase}) : super(AuthInitial()) {
    on<LoginButtonPressed>((event, emit) async {
      emit(AuthLoading());
      final result = await loginUseCase(event.username, event.password);
      result.fold(
        (failure) => emit(AuthError(failure)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });
  }
}
