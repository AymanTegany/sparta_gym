import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payments_repository.dart';

class AddPaymentUseCase implements UseCase<Payment, Payment> {
  final PaymentsRepository repository;

  AddPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, Payment>> call(Payment params) async {
    return await repository.addPayment(params);
  }
}
