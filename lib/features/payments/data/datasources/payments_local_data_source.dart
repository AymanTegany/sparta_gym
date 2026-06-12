import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/payment_model.dart';

abstract class PaymentsLocalDataSource {
  Future<PaymentModel> addPayment(PaymentModel payment);
  Future<List<PaymentModel>> getPaymentsByMember(String memberId);
  Future<List<PaymentModel>> getAllPayments();
  Future<Map<String, dynamic>> getPaymentStats();
}

class PaymentsLocalDataSourceImpl implements PaymentsLocalDataSource {
  final DatabaseHelper databaseHelper;

  PaymentsLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<PaymentModel> addPayment(PaymentModel payment) async {
    try {
      final db = await databaseHelper.database;
      int insertedId = 0;

      // تنفيذ الحفظ وتحديث الأرصدة في معاملة واحدة (Transaction)
      await db.transaction((txn) async {
        // 1. فحص وجود العضو وجلب أرصدته الحالية
        final memberResults = await txn.query(
          'members',
          where: 'memberId = ?',
          whereArgs: [payment.memberId],
          limit: 1,
        );

        if (memberResults.isEmpty) {
          throw const DatabaseException('العضو غير مسجل في النظام');
        }

        final memberData = memberResults.first;
        final currentPaid = (memberData['paidAmount'] as num).toDouble();
        final currentRemaining = (memberData['remainingAmount'] as num).toDouble();

        // التحقق من أن المبلغ لا يتخطى المديونية المتبقية
        if (payment.amount > currentRemaining) {
          throw const DatabaseException('المبلغ المدفوع أكبر من المديونية المتبقية على العضو');
        }

        // 2. إدخال سجل الدفعة
        insertedId = await txn.insert('payments', payment.toMap());

        // 3. تحديث أرصدة العضو
        final newPaid = currentPaid + payment.amount;
        final newRemaining = currentRemaining - payment.amount;

        await txn.update(
          'members',
          {
            'paidAmount': newPaid,
            'remainingAmount': newRemaining < 0 ? 0.0 : newRemaining,
          },
          where: 'memberId = ?',
          whereArgs: [payment.memberId],
        );
      });

      // 4. جلب سجل الدفعة بعد نجاح المعاملة مع بيانات العضو
      final result = await db.rawQuery('''
        SELECT p.*, m.fullName, m.phoneNumber
        FROM payments p
        LEFT JOIN members m ON p.memberId = m.memberId
        WHERE p.id = ?
      ''', [insertedId]);

      return PaymentModel.fromMap(result.first);
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw DatabaseException('فشل في تسجيل الدفعة: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByMember(String memberId) async {
    try {
      final db = await databaseHelper.database;
      final results = await db.rawQuery('''
        SELECT p.*, m.fullName, m.phoneNumber
        FROM payments p
        LEFT JOIN members m ON p.memberId = m.memberId
        WHERE p.memberId = ?
        ORDER BY p.paymentDate DESC
      ''', [memberId]);

      return results.map((map) => PaymentModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب مدفوعات العضو: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getAllPayments() async {
    try {
      final db = await databaseHelper.database;
      final results = await db.rawQuery('''
        SELECT p.*, m.fullName, m.phoneNumber
        FROM payments p
        LEFT JOIN members m ON p.memberId = m.memberId
        ORDER BY p.paymentDate DESC
      ''');

      return results.map((map) => PaymentModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب جميع المدفوعات: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      final db = await databaseHelper.database;
      final nowStr = DateTime.now().toIso8601String();
      final todayStr = nowStr.substring(0, 10);
      final monthStr = nowStr.substring(0, 7);

      // 1. إيراد اليوم
      final todayResult = await db.rawQuery('''
        SELECT SUM(amount) as total FROM payments WHERE paymentDate LIKE ?
      ''', ['$todayStr%']);
      final todayRevenue = (todayResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // 2. إيراد الشهر
      final monthResult = await db.rawQuery('''
        SELECT SUM(amount) as total FROM payments WHERE paymentDate LIKE ?
      ''', ['$monthStr%']);
      final monthRevenue = (monthResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // 3. إجمالي الإيرادات
      final totalResult = await db.rawQuery('''
        SELECT SUM(amount) as total FROM payments
      ''');
      final totalRevenue = (totalResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // 4. إجمالي المديونيات
      final debtResult = await db.rawQuery('''
        SELECT SUM(remainingAmount) as total FROM members
      ''');
      final totalDebts = (debtResult.first['total'] as num?)?.toDouble() ?? 0.0;

      return {
        'todayRevenue': todayRevenue,
        'monthRevenue': monthRevenue,
        'totalRevenue': totalRevenue,
        'totalDebts': totalDebts,
      };
    } catch (e) {
      throw DatabaseException('فشل في جلب إحصائيات المدفوعات: $e');
    }
  }
}
