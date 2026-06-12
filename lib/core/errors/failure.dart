import 'package:equatable/equatable.dart';

/// كلاس أساسي يمثل فشل عملية معينة (Failure)، ويحتوي عادة على رسالة خطأ ليتم عرضها في الـ UI.
abstract class Failure extends Equatable {
  final String message;
  const Failure([this.message = 'حدث خطأ غير متوقع']);

  @override
  List<Object> get props => [message];
}

/// فشل ناتج عن الخادم (API)
class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

/// فشل ناتج عن التخزين المحلي (Cache/Database)
class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

/// فشل ناتج عن انقطاع الإنترنت
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت']);
}
