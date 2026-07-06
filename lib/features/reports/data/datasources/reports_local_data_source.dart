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
      
      final startStr = startDate.toIso8601String();
      final endStr = endDate.toIso8601String();

      // 1. New Subscriptions (Payments with 'دفعة أولى' and NOT 'تمرينة واحدة')
      // Wait, let's use notes to filter. Single session is usually a membership named "تمرينة واحدة".
      // When a membership is "تمرينة واحدة", the payment notes might say "دفعة أولى لاشتراك تمرينة واحدة".
      // We will separate single sessions from new members/renewals.
      
      final paymentsResult = await db.rawQuery('''
        SELECT p.amount, p.paymentDate, p.notes, m.fullName, m.membershipType 
        FROM payments p 
        LEFT JOIN members m ON p.memberId = m.memberId
        WHERE p.paymentDate >= ? AND p.paymentDate <= ?
      ''', [startStr, endStr]);

      List<ReportPaymentItem> newMembers = [];
      List<ReportPaymentItem> renewals = [];
      List<ReportPaymentItem> singleSessions = [];

      for (var row in paymentsResult) {
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        final date = row['paymentDate'] as String? ?? '';
        final notes = row['notes'] as String? ?? '';
        final fullName = row['fullName'] as String? ?? 'مستخدم غير معروف';
        final membershipType = row['membershipType'] as String? ?? '';

        final item = ReportPaymentItem(
          memberName: fullName,
          notes: notes,
          amount: amount,
          date: date,
        );

        if (membershipType.contains('تمرينة') || membershipType.contains('حصة') || membershipType.contains('يوم') || notes.contains('حصة') || notes.contains('تمرينة') || notes.contains('يوم')) {
          singleSessions.add(item);
        } else if (notes.contains('تجديد')) {
          renewals.add(item);
        } else if (notes.contains('دفعة أولى')) {
          newMembers.add(item);
        } else {
          // Fallback if not matching
          newMembers.add(item);
        }
      }

      // 4. Expenses
      final expensesResult = await db.rawQuery('''
        SELECT title, category, amount, date, notes 
        FROM expenses 
        WHERE date >= ? AND date <= ?
      ''', [startStr, endStr]);

      List<ReportExpenseItem> expenses = expensesResult.map((row) {
        return ReportExpenseItem(
          title: row['title'] as String? ?? '',
          category: row['category'] as String? ?? '',
          amount: (row['amount'] as num?)?.toDouble() ?? 0.0,
          date: row['date'] as String? ?? '',
          notes: row['notes'] as String? ?? '',
        );
      }).toList();

      // 5. Attendance
      final attendanceResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM attendance WHERE checkInTime >= ? AND checkInTime <= ?',
        [startStr, endStr],
      );
      final totalAttendance = attendanceResult.first['count'] as int? ?? 0;

      // 6. Unpaid Subscriptions (اشتراكات على الحساب)
      final unpaidResult = await db.rawQuery('''
        SELECT fullName, membershipType, remainingAmount, startDate 
        FROM members 
        WHERE startDate >= ? AND startDate <= ? AND remainingAmount > 0
      ''', [startStr, endStr]);

      List<ReportPaymentItem> unpaidSubscriptions = unpaidResult.map((row) {
        return ReportPaymentItem(
          memberName: row['fullName'] as String? ?? 'غير معروف',
          notes: row['membershipType'] as String? ?? 'اشتراك آجل',
          amount: (row['remainingAmount'] as num?)?.toDouble() ?? 0.0,
          date: row['startDate'] as String? ?? '',
        );
      }).toList();

      // 7. Inventory Sales (مبيعات المخزون)
      final inventoryResult = await db.rawQuery('''
        SELECT SUM(finalAmount) as total 
        FROM pos_sales 
        WHERE date >= ? AND date <= ?
      ''', [startStr, endStr]);
      final inventorySalesRevenue = (inventoryResult.first['total'] as num?)?.toDouble() ?? 0.0;

      return ReportStats(
        newMembers: newMembers,
        renewals: renewals,
        singleSessions: singleSessions,
        unpaidSubscriptions: unpaidSubscriptions,
        expenses: expenses,
        totalAttendance: totalAttendance,
        inventorySalesRevenue: inventorySalesRevenue,
      );
    } catch (e) {
      throw DatabaseException('فشل في جلب إحصائيات التقارير: $e');
    }
  }
}
