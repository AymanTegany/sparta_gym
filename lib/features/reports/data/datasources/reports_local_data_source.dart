import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../../domain/entities/report_stats.dart';

abstract class ReportsLocalDataSource {
  Future<ReportStats> getReportStats(DateTime startDate, DateTime endDate);
}

class ReportsLocalDataSourceImpl implements ReportsLocalDataSource {
  final DatabaseHelper databaseHelper;

  ReportsLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<ReportStats> getReportStats(DateTime startDate, DateTime endDate) async {
    try {
      final db = await databaseHelper.database;
      
      // Formatting dates to match YYYY-MM-DD
      // We will append time to cover the whole day for end date if not provided,
      // but usually the query is between start of day and end of day.
      final startStr = startDate.toIso8601String().substring(0, 10) + 'T00:00:00.000';
      final endStr = endDate.toIso8601String().substring(0, 10) + 'T23:59:59.999';

      // 1. New Subscriptions Revenue
      final newSubsResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM payments WHERE paymentDate >= ? AND paymentDate <= ? AND notes LIKE ?',
        [startStr, endStr, '%دفعة أولى%'],
      );
      final newSubscriptionsRevenue = (newSubsResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // 2. Renewals Revenue
      final renewalsResult = await db.rawQuery(
        'SELECT SUM(amount) as total FROM payments WHERE paymentDate >= ? AND paymentDate <= ? AND notes LIKE ?',
        [startStr, endStr, '%تجديد%'],
      );
      final renewalsRevenue = (renewalsResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // 3. Inventory Sales
      final inventoryResult = await db.rawQuery(
        'SELECT SUM(finalAmount) as total FROM pos_sales WHERE date >= ? AND date <= ?',
        [startStr, endStr],
      );
      final inventorySalesRevenue = (inventoryResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // 4. Attendance
      final attendanceResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM attendance WHERE checkInTime >= ? AND checkInTime <= ?',
        [startStr, endStr],
      );
      final totalAttendance = attendanceResult.first['count'] as int? ?? 0;

      return ReportStats(
        newSubscriptionsRevenue: newSubscriptionsRevenue,
        renewalsRevenue: renewalsRevenue,
        inventorySalesRevenue: inventorySalesRevenue,
        totalAttendance: totalAttendance,
      );
    } catch (e) {
      throw DatabaseException('فشل في جلب إحصائيات التقارير: $e');
    }
  }
}
