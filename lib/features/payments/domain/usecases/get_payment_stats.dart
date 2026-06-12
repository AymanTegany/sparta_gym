import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/payments_repository.dart';

class GetPaymentStatsUseCase implements UseCase<Map<String, dynamic>, NoParams> {
  final PaymentsRepository repository;

  GetPaymentStatsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(NoParams params) async {
    return await repository.getPaymentStats();
  }
}
