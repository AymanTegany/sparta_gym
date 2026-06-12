import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../../members/domain/entities/member_entity.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final List<Attendance> dailyAttendance;
  final Map<String, dynamic> stats;
  final List<Member> searchResults;

  const AttendanceLoaded({
    required this.dailyAttendance,
    required this.stats,
    this.searchResults = const [],
  });

  AttendanceLoaded copyWith({
    List<Attendance>? dailyAttendance,
    Map<String, dynamic>? stats,
    List<Member>? searchResults,
  }) {
    return AttendanceLoaded(
      dailyAttendance: dailyAttendance ?? this.dailyAttendance,
      stats: stats ?? this.stats,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  List<Object?> get props => [dailyAttendance, stats, searchResults];
}

class AttendanceActionSuccess extends AttendanceState {
  final Attendance attendance;
  final String type; // "حضور" أو "انصراف"
  final String message;

  const AttendanceActionSuccess({
    required this.attendance,
    required this.type,
    required this.message,
  });

  @override
  List<Object?> get props => [attendance, type, message];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError(this.message);

  @override
  List<Object?> get props => [message];
}
