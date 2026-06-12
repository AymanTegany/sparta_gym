import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_local_data_source.dart';
import '../models/payment_model.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsLocalDataSource localDataSource;

  PaymentsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Payment>> addPayment(Payment payment) async {
    try {
      final paymentModel = PaymentModel.fromEntity(payment);
      final result = await localDataSource.addPayment(paymentModel);
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في تسجيل الدفعة: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByMember(String memberId) async {
    try {
      final result = await localDataSource.getPaymentsByMember(memberId);
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في جلب مدفوعات العضو: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getAllPayments() async {
    try {
      final result = await localDataSource.getAllPayments();
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في جلب السجلات: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPaymentStats() async {
    try {
      final stats = await localDataSource.getPaymentStats();
      return Right(stats);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('فشل في جلب الإحصائيات: $e'));
    }
  }
}
