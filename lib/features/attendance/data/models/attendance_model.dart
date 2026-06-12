import '../../domain/entities/attendance_entity.dart';

/// نموذج الحضور والانصراف (Attendance Model)
class AttendanceModel extends Attendance {
  const AttendanceModel({
    super.id,
    required super.memberId,
    super.memberName,
    super.memberPhone,
    required super.checkInTime,
    super.checkOutTime,
    super.durationMinutes,
  });

  /// التحويل من Map (التي تنتج عن استعلام SQLite)
  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as int?,
      memberId: map['memberId'] as String,
      memberName: map['fullName'] as String?, // ينتج عن دمج (JOIN) جدول الأعضاء
      memberPhone: map['phoneNumber'] as String?, // ينتج عن دمج (JOIN) جدول الأعضاء
      checkInTime: map['checkInTime'] as String,
      checkOutTime: map['checkOutTime'] as String?,
      durationMinutes: map['durationMinutes'] as int?,
    );
  }

  /// التحويل إلى Map لإضافتها أو تعديلها في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'memberId': memberId,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'durationMinutes': durationMinutes,
    };
  }

  /// التحويل من Entity إلى Model
  factory AttendanceModel.fromEntity(Attendance entity) {
    return AttendanceModel(
      id: entity.id,
      memberId: entity.memberId,
      memberName: entity.memberName,
      memberPhone: entity.memberPhone,
      checkInTime: entity.checkInTime,
      checkOutTime: entity.checkOutTime,
      durationMinutes: entity.durationMinutes,
    );
  }
}
