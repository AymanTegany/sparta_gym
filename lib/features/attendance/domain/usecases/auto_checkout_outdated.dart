import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/attendance_repository.dart';

class AutoCheckoutOutdatedUseCase implements UseCase<void, int> {
  final AttendanceRepository repository;

  AutoCheckoutOutdatedUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int params) async {
    return await repository.autoCheckoutOutdatedAttendances(params);
  }
}
