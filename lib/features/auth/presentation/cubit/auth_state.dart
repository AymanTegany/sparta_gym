import 'package:equatable/equatable.dart';
import 'package:sparta_gym/features/auth/domain/entities/user.dart';


/// حالات نظام المصادقة.
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// الحالة الأولية — لم يتم التحقق بعد.
class AuthInitial extends AuthState {}

/// جاري التحميل (تسجيل دخول / إنشاء حساب / فحص جلسة).
class AuthLoading extends AuthState {}

/// تم تسجيل الدخول بنجاح.
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// لم يتم تسجيل الدخول.
class AuthUnauthenticated extends AuthState {}

/// خطأ في المصادقة.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// تم إنشاء الحساب بنجاح — ينتقل إلى صفحة الدخول.
class AuthRegistered extends AuthState {
  final String username;
  const AuthRegistered(this.username);

  @override
  List<Object?> get props => [username];
}
