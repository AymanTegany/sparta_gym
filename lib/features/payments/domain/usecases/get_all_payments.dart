import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payments_repository.dart';

class GetAllPaymentsUseCase implements UseCase<List<Payment>, NoParams> {
  final PaymentsRepository repository;

  GetAllPaymentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Payment>>> call(NoParams params) async {
    return await repository.getAllPayments();
  }
}
