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

      return await db.transaction((txn) async {
        // 1. البحث عن العضو في قاعدة البيانات
        final memberResults = await txn.query(
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
        if (endDate == null) {
          throw const DatabaseException('تاريخ انتهاء الاشتراك غير صالح.');
        }

        final today = DateTime(now.year, now.month, now.day);
        final endDay = DateTime(endDate.year, endDate.month, endDate.day);

        if (endDay.isBefore(today)) {
          throw const DatabaseException('اشتراك العضو منتهي الصلاحية! لا يمكن تسجيل الحضور.');
        }

        final String startDateStr = memberData['startDate'] as String;
        final String membershipType = memberData['membershipType'] as String;

        // 2.5 التحقق من عدد زيارات الباقة المشترك فيها العضو
        final membershipResults = await txn.query(
          'memberships',
          where: 'name = ?',
          whereArgs: [membershipType],
          limit: 1,
        );

        if (membershipResults.isNotEmpty) {
          final membershipData = membershipResults.first;
          final int? visitsLimit = membershipData['visitsLimit'] as int?;
          if (visitsLimit != null) {
            final attendanceCountResult = await txn.rawQuery('''
              SELECT COUNT(*) as count FROM attendance 
              WHERE memberId = ? AND checkInTime >= ?
            ''', [memberId, '${startDateStr}T00:00:00']);
            
            final int attendanceCount = attendanceCountResult.first['count'] as int? ?? 0;
            if (attendanceCount >= visitsLimit) {
              throw const DatabaseException('عذراً، لقد انتهى عدد الزيارات المسموح بها في الباقة المشترك فيها العضو!');
            }
          }
        }

        // 3. التحقق مما إذا كان العضو مسجلاً حضوراً حالياً (ولم يسجل خروجاً بعد)
        final activeCheckIn = await txn.query(
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
        final id = await txn.insert('attendance', {
          'memberId': memberId,
          'checkInTime': nowStr,
          'checkOutTime': null,
          'durationMinutes': null,
        });

        // 5. جلب السجل بعد الحفظ مع تفاصيل العضو (JOIN)
        final results = await txn.rawQuery('''
          SELECT a.*, m.fullName, m.phoneNumber 
          FROM attendance a
          LEFT JOIN members m ON a.memberId = m.memberId
          WHERE a.id = ?
        ''', [id]);

        return AttendanceModel.fromMap(results.first);
      });
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

      return await db.transaction((txn) async {
        // 1. البحث عن العضو للحصول على معرف العضوية الصحيح
        final memberResults = await txn.query(
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
        final activeCheckInResults = await txn.query(
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
        await txn.update(
          'attendance',
          {
            'checkOutTime': nowStr,
            'durationMinutes': duration < 0 ? 0 : duration,
          },
          where: 'id = ?',
          whereArgs: [recordId],
        );

        // 5. جلب السجل بعد التحديث
        final results = await txn.rawQuery('''
          SELECT a.*, m.fullName, m.phoneNumber 
          FROM attendance a
          LEFT JOIN members m ON a.memberId = m.memberId
          WHERE a.id = ?
        ''', [recordId]);

        return AttendanceModel.fromMap(results.first);
      });
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
      // استخدام نطاق زمني بدلاً من date() لتسريع الاستعلام مع الفهارس
      final dayStart = '${dateStr}T00:00:00';
      final nextDay = DateTime.parse(dateStr).add(const Duration(days: 1));
      final dayEnd = '${nextDay.toIso8601String().substring(0, 10)}T00:00:00';

      final results = await db.rawQuery('''
        SELECT a.*, m.fullName, m.phoneNumber 
        FROM attendance a
        LEFT JOIN members m ON a.memberId = m.memberId
        WHERE a.checkInTime >= ? AND a.checkInTime < ?
        ORDER BY COALESCE(a.checkOutTime, a.checkInTime) DESC
      ''', [dayStart, dayEnd]);

      return results.map((map) => AttendanceModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب سجلات الحضور: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final db = await databaseHelper.database;
      final now = DateTime.now();
      final todayStart = '${now.toIso8601String().substring(0, 10)}T00:00:00';
      final tomorrowStart = '${now.add(const Duration(days: 1)).toIso8601String().substring(0, 10)}T00:00:00';
      // أول يوم في الشهر الحالي
      final monthStart = '${now.toIso8601String().substring(0, 7)}-01T00:00:00';

      // 1. عدد حضور اليوم (باستخدام نطاق زمني بدلاً من date())
      final todayCountResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM attendance 
        WHERE checkInTime >= ? AND checkInTime < ?
      ''', [todayStart, tomorrowStart]);
      final todayCount = todayCountResult.first['count'] as int? ?? 0;

      // 2. متوسط الحضور اليومي للشهر الحالي
      final avgResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_attendance, 
          COUNT(DISTINCT substr(checkInTime, 1, 10)) as total_days 
        FROM attendance
        WHERE checkInTime >= ?
      ''', [monthStart]);
      final totalAttendance = avgResult.first['total_attendance'] as int? ?? 0;
      final totalDays = avgResult.first['total_days'] as int? ?? 0;
      final avgDaily = totalDays > 0 ? (totalAttendance / totalDays) : 0.0;

      // 3. الأعضاء الأكثر حضوراً في الشهر الحالي
      final topResult = await db.rawQuery('''
        SELECT m.fullName, m.phoneNumber, COUNT(a.id) as attendanceCount
        FROM attendance a
        JOIN members m ON a.memberId = m.memberId
        WHERE a.checkInTime >= ?
        GROUP BY a.memberId
        ORDER BY attendanceCount DESC
        LIMIT 5
      ''', [monthStart]);

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
      // حساب الحد الأقصى للوقت (الآن - maxHours ساعة)
      final cutoffTime = now.subtract(Duration(hours: maxHours));

      // تحديث جميع السجلات المعلقة القديمة دفعة واحدة بدلاً من التكرار
      // وقت الخروج = وقت الدخول + 60 دقيقة، المدة = 60 دقيقة
      await db.rawUpdate('''
        UPDATE attendance 
        SET checkOutTime = datetime(checkInTime, '+60 minutes'),
            durationMinutes = 60
        WHERE checkOutTime IS NULL 
          AND checkInTime < ?
      ''', [cutoffTime.toIso8601String()]);
    } catch (e) {
      // نتجاهل الخطأ بدلاً من رميه لأن هذه عملية تنظيف غير حرجة
      // ولا يجب أن تمنع تسجيل الحضور
    }
  }

  @override
  Future<bool> isMemberCheckedIn(String barcodeOrPhone) async {
    try {
      final db = await databaseHelper.database;
      // استعلام واحد بدلاً من اثنين: البحث عن العضو + التحقق من الحضور النشط
      final results = await db.rawQuery('''
        SELECT 1 FROM attendance a
        JOIN members m ON a.memberId = m.memberId
        WHERE (m.memberId = ? OR m.phoneNumber = ?) 
          AND a.checkOutTime IS NULL
        LIMIT 1
      ''', [barcodeOrPhone, barcodeOrPhone]);

      return results.isNotEmpty;
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
