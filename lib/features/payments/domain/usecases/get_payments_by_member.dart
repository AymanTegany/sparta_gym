import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payments_repository.dart';

class GetPaymentsByMemberUseCase implements UseCase<List<Payment>, String> {
  final PaymentsRepository repository;

  GetPaymentsByMemberUseCase(this.repository);

  @override
  Future<Either<Failure, List<Payment>>> call(String params) async {
    return await repository.getPaymentsByMember(params);
  }
}
