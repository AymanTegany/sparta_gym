import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceStatsUseCase implements UseCase<Map<String, dynamic>, NoParams> {
  final AttendanceRepository repository;

  GetAttendanceStatsUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(NoParams params) async {
    return await repository.getAttendanceStats();
  }
}
