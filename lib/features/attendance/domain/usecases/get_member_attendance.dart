import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetMemberAttendanceUseCase implements UseCase<List<Attendance>, String> {
  final AttendanceRepository repository;

  GetMemberAttendanceUseCase(this.repository);

  @override
  Future<Either<Failure, List<Attendance>>> call(String params) async {
    return await repository.getMemberAttendance(params);
  }
}
