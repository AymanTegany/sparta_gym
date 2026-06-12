/// طبقة: Presentation (Bloc / Cubit)
/// 
/// ملف: auth_state.dart
/// يحتوي على الحالات الممكنة لواجهة المستخدم (مثل: جاري التحميل، نجاح، فشل مع رسالة خطأ).

import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
