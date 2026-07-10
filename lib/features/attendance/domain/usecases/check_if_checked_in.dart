import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/attendance_repository.dart';

class CheckIfCheckedInUseCase implements UseCase<bool, String> {
  final AttendanceRepository repository;

  CheckIfCheckedInUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String params) async {
    return await repository.isMemberCheckedIn(params);
  }
}
