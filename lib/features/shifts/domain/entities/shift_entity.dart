import 'package:equatable/equatable.dart';

/// كيان الشفت
class Shift extends Equatable {
  final int? id;
  final int employeeId;
  final String employeeName;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final String? notes;

  const Shift({
    this.id,
    required this.employeeId,
    required this.employeeName,
    required this.startTime,
    this.endTime,
    this.isActive = true,
    this.notes,
  });

  /// مدة الشفت بالدقائق
  int get durationMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  /// مدة الشفت كنص مقروء
  String get durationText {
    final mins = durationMinutes;
    final hours = mins ~/ 60;
    final remaining = mins % 60;
    if (hours > 0) {
      return '$hours ساعة و $remaining دقيقة';
    }
    return '$remaining دقيقة';
  }

  Shift copyWith({
    int? id,
    int? employeeId,
    String? employeeName,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
    String? notes,
  }) {
    return Shift(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, employeeId, employeeName, startTime, endTime, isActive];
}
