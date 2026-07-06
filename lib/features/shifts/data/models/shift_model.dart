import '../../domain/entities/shift_entity.dart';

class ShiftModel extends Shift {
  const ShiftModel({
    super.id,
    required super.employeeId,
    required super.employeeName,
    required super.startTime,
    super.endTime,
    super.isActive = true,
    super.notes,
  });

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'] as int?,
      employeeId: map['employeeId'] as int,
      employeeName: map['employeeName'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.tryParse(map['endTime'] as String)
          : null,
      isActive: (map['isActive'] as int?) == 1,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  factory ShiftModel.fromEntity(Shift entity) {
    return ShiftModel(
      id: entity.id,
      employeeId: entity.employeeId,
      employeeName: entity.employeeName,
      startTime: entity.startTime,
      endTime: entity.endTime,
      isActive: entity.isActive,
      notes: entity.notes,
    );
  }
}
