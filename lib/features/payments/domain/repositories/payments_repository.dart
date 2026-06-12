import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/payment_entity.dart';

/// واجهة مستودع المدفوعات (Payments Repository Interface)
abstract class PaymentsRepository {
  /// تسجيل دفعة جديدة وتحديث رصيد العضو
  Future<Either<Failure, Payment>> addPayment(Payment payment);

  /// جلب مدفوعات عضو معين
  Future<Either<Failure, List<Payment>>> getPaymentsByMember(String memberId);

  /// جلب كل المدفوعات في الجيم
  Future<Either<Failure, List<Payment>>> getAllPayments();

  /// جلب الإحصائيات المالية
  Future<Either<Failure, Map<String, dynamic>>> getPaymentStats();
}
