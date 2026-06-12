import 'package:equatable/equatable.dart';

/// كيان الحضور والانصراف (Attendance Entity)
class Attendance extends Equatable {
  final int? id;
  final String memberId;
  final String? memberName;
  final String? memberPhone;
  final String checkInTime;
  final String? checkOutTime;
  final int? durationMinutes;

  const Attendance({
    this.id,
    required this.memberId,
    this.memberName,
    this.memberPhone,
    required this.checkInTime,
    this.checkOutTime,
    this.durationMinutes,
  });

  @override
  List<Object?> get props => [
        id,
        memberId,
        memberName,
        memberPhone,
        checkInTime,
        checkOutTime,
        durationMinutes,
      ];
}
