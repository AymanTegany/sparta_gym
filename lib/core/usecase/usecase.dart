import 'package:dartz/dartz.dart';
import '../errors/failure.dart';

/// واجهة برمجية موحدة (Interface) يجب أن ترث منها جميع الـ Usecases في التطبيق.
/// Type: نوع البيانات المرجعة في حالة النجاح.
/// Params: المتغيرات المطلوبة لتنفيذ العملية.
abstract class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

/// كلاس يستخدم إذا كانت الدالة لا تحتاج إلى معاملات (Parameters).
class NoParams {}
