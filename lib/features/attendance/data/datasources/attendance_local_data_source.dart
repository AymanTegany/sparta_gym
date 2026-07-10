import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/attendance_model.dart';

/// واجهة مصدر بيانات الحضور والانصراف (Attendance Local Datasource Interface)
abstract class AttendanceLocalDataSource {
  Future<AttendanceModel> checkInMember(String barcodeOrPhone);
  Future<AttendanceModel> checkOutMember(String barcodeOrPhone);
  Future<List<AttendanceModel>> getDailyAttendance(String dateStr);
  Future<Map<String, dynamic>> getAttendanceStats();
  Future<void> autoCheckoutOutdatedAttendances(int maxHours);
  Future<bool> isMemberCheckedIn(String barcodeOrPhone);
  Future<List<AttendanceModel>> getMemberAttendance(String memberId);
}

/// تنفيذ مصدر بيانات الحضور والانصراف باستخدام SQLite
class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  final DatabaseHelper databaseHelper;

  AttendanceLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<AttendanceModel> checkInMember(String barcodeOrPhone) async {
    try {
      final db = await databaseHelper.database;

      // 1. البحث عن العضو في قاعدة البيانات
      final memberResults = await db.query(
        'members',
        where: 'memberId = ? OR phoneNumber = ?',
        whereArgs: [barcodeOrPhone, barcodeOrPhone],
        limit: 1,
      );

      if (memberResults.isEmpty) {
        throw const DatabaseException('العضو غير مسجل في النظام');
      }

      final memberData = memberResults.first;
      final String memberId = memberData['memberId'] as String;
      final String endDateStr = memberData['endDate'] as String;

      // 2. التحقق من انتهاء اشتراك العضو
      final endDate = DateTime.tryParse(endDateStr);
      final now = DateTime.now();
      if (endDate == null || endDate.isBefore(now)) {
        throw const DatabaseException('اشتراك العضو منتهي الصلاحية! لا يمكن تسجيل الحضور.');
      }

      final String startDateStr = memberData['startDate'] as String;
      final String membershipType = memberData['membershipType'] as String;

      // 2.5 التحقق من عدد زيارات الباقة المشترك فيها العضو
      final membershipResults = await db.query(
        'memberships',
        where: 'name = ?',
        whereArgs: [membershipType],
        limit: 1,
      );

      if (membershipResults.isNotEmpty) {
        final membershipData = membershipResults.first;
        final int? visitsLimit = membershipData['visitsLimit'] as int?;
        if (visitsLimit != null) {
          final attendanceCountResult = await db.rawQuery('''
            SELECT COUNT(*) as count FROM attendance 
            WHERE memberId = ? AND checkInTime >= ?
          ''', [memberId, startDateStr]);
          
          final int attendanceCount = attendanceCountResult.first['count'] as int? ?? 0;
          if (attendanceCount >= visitsLimit) {
            throw const DatabaseException('عذراً، لقد انتهى عدد الزيارات المسموح بها في الباقة المشترك فيها العضو!');
          }
        }
      }

      // 3. التحقق مما إذا كان العضو مسجلاً حضوراً حالياً (ولم يسجل خروجاً بعد)
      final activeCheckIn = await db.query(
        'attendance',
        where: 'memberId = ? AND checkOutTime IS NULL',
        whereArgs: [memberId],
        limit: 1,
      );

      if (activeCheckIn.isNotEmpty) {
        throw const DatabaseException('العضو مسجل حضور بالفعل ولم يقم بتسجيل الخروج بعد.');
      }

      // 4. تسجيل الدخول
      final nowStr = now.toIso8601String();
      final id = await db.insert('attendance', {
        'memberId': memberId,
        'checkInTime': nowStr,
        'checkOutTime': null,
        'durationMinutes': null,
      });

      // 5. جلب السجل بعد الحفظ مع تفاصيل العضو (JOIN)
      final results = await db.rawQuery('''
        SELECT a.*, m.fullName, m.phoneNumber 
        FROM attendance a
        LEFT JOIN members m ON a.memberId = m.memberId
        WHERE a.id = ?
      ''', [id]);

      return AttendanceModel.fromMap(results.first);
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('فشل في تسجيل الحضور: $e');
    }
  }

  @override
  Future<AttendanceModel> checkOutMember(String barcodeOrPhone) async {
    try {
      final db = await databaseHelper.database;

      // 1. البحث عن العضو للحصول على معرف العضوية الصحيح
      final memberResults = await db.query(
        'members',
        where: 'memberId = ? OR phoneNumber = ?',
        whereArgs: [barcodeOrPhone, barcodeOrPhone],
        limit: 1,
      );

      if (memberResults.isEmpty) {
        throw const DatabaseException('العضو غير مسجل في النظام');
      }

      final memberData = memberResults.first;
      final String memberId = memberData['memberId'] as String;

      // 2. البحث عن تسجيل دخول نشط للعضو (لم يسجل خروجاً بعد)
      final activeCheckInResults = await db.query(
        'attendance',
        where: 'memberId = ? AND checkOutTime IS NULL',
        whereArgs: [memberId],
        orderBy: 'checkInTime DESC',
        limit: 1,
      );

      if (activeCheckInResults.isEmpty) {
        throw const DatabaseException('لا يوجد تسجيل دخول نشط لهذا العضو لتسجيل خروجه.');
      }

      final activeCheckIn = activeCheckInResults.first;
      final int recordId = activeCheckIn['id'] as int;
      final String checkInTimeStr = activeCheckIn['checkInTime'] as String;

      // 3. حساب مدة التمرين
      final now = DateTime.now();
      final checkInTime = DateTime.parse(checkInTimeStr);
      final duration = now.difference(checkInTime).inMinutes;

      // 4. تسجيل الانصراف وتحديث السجل
      final nowStr = now.toIso8601String();
      await db.update(
        'attendance',
        {
          'checkOutTime': nowStr,
          'durationMinutes': duration < 0 ? 0 : duration,
        },
        where: 'id = ?',
        whereArgs: [recordId],
      );

      // 5. جلب السجل بعد التحديث
      final results = await db.rawQuery('''
        SELECT a.*, m.fullName, m.phoneNumber 
        FROM attendance a
        LEFT JOIN members m ON a.memberId = m.memberId
        WHERE a.id = ?
      ''', [recordId]);

      return AttendanceModel.fromMap(results.first);
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('فشل في تسجيل الانصراف: $e');
    }
  }

  @override
  Future<List<AttendanceModel>> getDailyAttendance(String dateStr) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.rawQuery('''
        SELECT a.*, m.fullName, m.phoneNumber 
        FROM attendance a
        LEFT JOIN members m ON a.memberId = m.memberId
        WHERE a.checkInTime LIKE ?
        ORDER BY a.checkInTime DESC
      ''', ['$dateStr%']);

      return results.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب سجلات الحضور: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final db = await databaseHelper.database;
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      // 1. عدد حضور اليوم
      final todayCountResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM attendance WHERE checkInTime LIKE ?
      ''', ['$todayStr%']);
      final todayCount = todayCountResult.first['count'] as int? ?? 0;

      // 2. متوسط الحضور اليومي
      final avgResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_attendance, 
          COUNT(DISTINCT substr(checkInTime, 1, 10)) as total_days 
        FROM attendance
      ''');
      final totalAttendance = avgResult.first['total_attendance'] as int? ?? 0;
      final totalDays = avgResult.first['total_days'] as int? ?? 0;
      final avgDaily = totalDays > 0 ? (totalAttendance / totalDays) : 0.0;

      // 3. الأعضاء الأكثر حضوراً
      final topResult = await db.rawQuery('''
        SELECT m.fullName, m.phoneNumber, COUNT(a.id) as attendanceCount
        FROM attendance a
        JOIN members m ON a.memberId = m.memberId
        GROUP BY a.memberId
        ORDER BY attendanceCount DESC
        LIMIT 5
      ''');

      final topMembers = topResult.map((row) => {
        'fullName': row['fullName'] as String,
        'phoneNumber': row['phoneNumber'] as String?,
        'count': row['attendanceCount'] as int,
      }).toList();

      return {
        'todayCount': todayCount,
        'averageDaily': avgDaily,
        'topMembers': topMembers,
      };
    } catch (e) {
      throw DatabaseException('فشل في جلب إحصائيات الحضور: $e');
    }
  }

  @override
  Future<void> autoCheckoutOutdatedAttendances(int maxHours) async {
    try {
      final db = await databaseHelper.database;
      final now = DateTime.now();

      final activeCheckIns = await db.query(
        'attendance',
        where: 'checkOutTime IS NULL',
      );

      for (var record in activeCheckIns) {
        final checkInTimeStr = record['checkInTime'] as String;
        final checkInTime = DateTime.tryParse(checkInTimeStr);
        
        if (checkInTime != null && now.difference(checkInTime).inHours >= maxHours) {
          final recordId = record['id'] as int;
          // Set checkout time to check-in time + maxHours
          final checkOutTime = checkInTime.add(Duration(hours: maxHours));
          final duration = maxHours * 60; 

          await db.update(
            'attendance',
            {
              'checkOutTime': checkOutTime.toIso8601String(),
              'durationMinutes': duration,
            },
            where: 'id = ?',
            whereArgs: [recordId],
          );
        }
      }
    } catch (e) {
      throw DatabaseException('فشل في إنهاء الجلسات المعلقة: $e');
    }
  }

  @override
  Future<bool> isMemberCheckedIn(String barcodeOrPhone) async {
    try {
      final db = await databaseHelper.database;
      final memberResults = await db.query(
        'members',
        where: 'memberId = ? OR phoneNumber = ?',
        whereArgs: [barcodeOrPhone, barcodeOrPhone],
        limit: 1,
      );

      if (memberResults.isEmpty) return false;

      final memberId = memberResults.first['memberId'] as String;
      final activeCheckIn = await db.query(
        'attendance',
        where: 'memberId = ? AND checkOutTime IS NULL',
        whereArgs: [memberId],
        limit: 1,
      );

      return activeCheckIn.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<AttendanceModel>> getMemberAttendance(String memberId) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.rawQuery('''
        SELECT a.*, m.fullName, m.phoneNumber 
        FROM attendance a
        LEFT JOIN members m ON a.memberId = m.memberId
        WHERE a.memberId = ?
        ORDER BY a.checkInTime DESC
      ''', [memberId]);

      return results.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب سجل حضور العضو: $e');
    }
  }
}
