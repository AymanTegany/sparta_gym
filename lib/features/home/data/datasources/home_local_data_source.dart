import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../../../members/data/models/member_model.dart';
import '../../../payments/data/models/payment_model.dart';
import '../../domain/entities/dashboard_stats.dart';

abstract class HomeLocalDataSource {
  Future<DashboardStats> getDashboardStats();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final DatabaseHelper databaseHelper;

  HomeLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<DashboardStats> getDashboardStats() async {
    try {
      final db = await databaseHelper.database;
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      final todayStr = nowStr.substring(0, 10);
      final currentMonthStr = nowStr.substring(0, 7); // YYYY-MM

      // 1. إجمالي الأعضاء
      final totalMembersResult = await db.rawQuery('SELECT COUNT(*) as count FROM members');
      final totalMembers = totalMembersResult.first['count'] as int? ?? 0;

      // 2. الأعضاء النشطون
      final activeMembersResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM members WHERE endDate >= ?',
        [nowStr],
      );
      final activeMembers = activeMembersResult.first['count'] as int? ?? 0;

      // 3. الاشتراكات المنتهية
      final expiredMembersResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM members WHERE endDate < ? AND membershipType != ?',
        [nowStr, 'تمرينة واحدة'],
      );
      final expiredMembers = expiredMembersResult.first['count'] as int? ?? 0;

      // 4. إيراد الشهر الحالي
      final monthlyRevenueResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM payments WHERE paymentDate LIKE ?',
        ['$currentMonthStr%'],
      );
      final monthlyRevenue = (monthlyRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // 5. اشتراكات تنتهي قريباً (خلال 7 أيام)
      final sevenDaysLaterStr = now.add(const Duration(days: 7)).toIso8601String();
      final expiringSoonResult = await db.rawQuery(
        'SELECT * FROM members WHERE endDate >= ? AND endDate <= ? ORDER BY endDate ASC',
        [nowStr, sevenDaysLaterStr],
      );
      final expiringSoonMembers = expiringSoonResult
          .map((map) => MemberModel.fromMap(map))
          .toList();

      // 6. آخر المدفوعات (أحدث 5 دفعات)
      final latestPaymentsResult = await db.rawQuery(
        'SELECT p.*, m.fullName as fullName, m.phoneNumber as phoneNumber '
        'FROM payments p '
        'LEFT JOIN members m ON p.memberId = m.memberId '
        'ORDER BY p.paymentDate DESC '
        'LIMIT 5',
      );
      final latestPayments = latestPaymentsResult
          .map((map) => PaymentModel.fromMap(map))
          .toList();

      // 7. حضور اليوم
      final todayAttendanceResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM attendance WHERE checkInTime LIKE ?',
        ['$todayStr%'],
      );
      final todayAttendance = todayAttendanceResult.first['count'] as int? ?? 0;

      // 8. الموجودون حالياً بالداخل
      final currentlyInsideResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM attendance WHERE checkInTime LIKE ? AND checkOutTime IS NULL',
        ['$todayStr%'],
      );
      final currentlyInside = currentlyInsideResult.first['count'] as int? ?? 0;

      // 9. بيانات الإيرادات لآخر 7 أيام
      final sevenDaysAgoStr = now.subtract(const Duration(days: 6)).toIso8601String().substring(0, 10);
      final revenueChartResult = await db.rawQuery(
        'SELECT SUBSTR(paymentDate, 1, 10) as date, SUM(amount) as total '
        'FROM payments '
        'WHERE paymentDate >= ? '
        'GROUP BY SUBSTR(paymentDate, 1, 10)',
        ['${sevenDaysAgoStr}T00:00:00'],
      );

      final Map<String, double> revenueChartData = {};
      // ملء الأيام السبعة افتراضياً بقيمة 0.0
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
        revenueChartData[date] = 0.0;
      }
      // ملء القيم الحقيقية المسترجعة من قاعدة البيانات
      for (final row in revenueChartResult) {
        final date = row['date'] as String?;
        final total = (row['total'] as num?)?.toDouble() ?? 0.0;
        if (date != null && revenueChartData.containsKey(date)) {
          revenueChartData[date] = total;
        }
      }

      // 10. التنبيهات
      final expiredAlertsCount = expiredMembers;

      final threeDaysLaterStr = now.add(const Duration(days: 3)).toIso8601String();
      final expiringThreeDaysResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM members WHERE endDate >= ? AND endDate <= ?',
        [nowStr, threeDaysLaterStr],
      );
      final expiringThreeDaysCount = expiringThreeDaysResult.first['count'] as int? ?? 0;

      return DashboardStats(
        totalMembers: totalMembers,
        activeMembers: activeMembers,
        expiredMembers: expiredMembers,
        monthlyRevenue: monthlyRevenue,
        expiringSoonMembers: expiringSoonMembers,
        latestPayments: latestPayments,
        todayAttendance: todayAttendance,
        currentlyInside: currentlyInside,
        revenueChartData: revenueChartData,
        expiredAlertsCount: expiredAlertsCount,
        expiringThreeDaysCount: expiringThreeDaysCount,
      );
    } catch (e) {
      throw DatabaseException('فشل في جلب إحصائيات لوحة التحكم: $e');
    }
  }
}
