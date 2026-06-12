import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/membership_model.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// مصدر بيانات باقات الاشتراكات محلياً (Memberships Local Datasource)
/// ──────────────────────────────────────────────────────────────────────────────
abstract class MembershipsLocalDataSource {
  Future<List<MembershipModel>> getAllMemberships();
  Future<int> addMembership(MembershipModel membership);
  Future<void> updateMembership(MembershipModel membership);
  Future<void> deleteMembership(int id);
}

class MembershipsLocalDataSourceImpl implements MembershipsLocalDataSource {
  final DatabaseHelper databaseHelper;
  static const String _tableName = 'memberships';

  MembershipsLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<MembershipModel>> getAllMemberships() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        _tableName,
        orderBy: 'id ASC',
      );
      return result.map((map) => MembershipModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب الباقات: $e');
    }
  }

  @override
  Future<int> addMembership(MembershipModel membership) async {
    try {
      final db = await databaseHelper.database;
      return await db.insert(_tableName, membership.toMap());
    } catch (e) {
      throw DatabaseException('فشل في إضافة الباقة: $e');
    }
  }

  @override
  Future<void> updateMembership(MembershipModel membership) async {
    try {
      final db = await databaseHelper.database;
      final count = await db.update(
        _tableName,
        membership.toMap(),
        where: 'id = ?',
        whereArgs: [membership.id],
      );
      if (count == 0) {
        throw const DatabaseException('الباقة غير موجودة لتحديثها');
      }
    } catch (e) {
      throw DatabaseException('فشل في تحديث الباقة: $e');
    }
  }

  @override
  Future<void> deleteMembership(int id) async {
    try {
      final db = await databaseHelper.database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException('الباقة غير موجودة لحذفها');
      }
    } catch (e) {
      throw DatabaseException('فشل في حذف الباقة: $e');
    }
  }
}
