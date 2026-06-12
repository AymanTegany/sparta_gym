import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class CheckInMemberUseCase implements UseCase<Attendance, String> {
  final AttendanceRepository repository;

  CheckInMemberUseCase(this.repository);

  @override
  Future<Either<Failure, Attendance>> call(String params) async {
    return await repository.checkInMember(params);
  }
}
