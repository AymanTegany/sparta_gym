import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetDailyAttendanceUseCase implements UseCase<List<Attendance>, String> {
  final AttendanceRepository repository;

  GetDailyAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, List<Attendance>>> call(String params) async {
    return await repository.getDailyAttendance(params);
  }
}
