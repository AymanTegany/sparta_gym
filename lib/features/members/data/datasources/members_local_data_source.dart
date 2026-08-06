import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/member_model.dart';

/// واجهة مصدر البيانات المحلي للعملاء
abstract class MembersLocalDataSource {
  Future<List<MemberModel>> getAllMembers();
  Future<MemberModel> getMemberById(int id);
  Future<int> addMember(MemberModel member);
  Future<void> updateMember(MemberModel member);
  Future<void> deleteMember(int id);
  Future<List<MemberModel>> searchMembers(String query);
}

/// تنفيذ مصدر البيانات المحلي باستخدام SQLite
class MembersLocalDataSourceImpl implements MembersLocalDataSource {
  final DatabaseHelper databaseHelper;

  MembersLocalDataSourceImpl({required this.databaseHelper});

  static const String _tableName = 'members';

  @override
  Future<List<MemberModel>> getAllMembers() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        _tableName,
        orderBy: 'createdAt DESC',
      );
      return result.map((map) => MemberModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب بيانات العملاء: $e');
    }
  }

  @override
  Future<MemberModel> getMemberById(int id) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isEmpty) {
        throw const DatabaseException('العميل غير موجود');
      }
      return MemberModel.fromMap(result.first);
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('فشل في جلب بيانات العميل: $e');
    }
  }

  @override
  Future<int> addMember(MemberModel member) async {
    try {
      if (member.fullName.trim().isEmpty) {
        throw const DatabaseException('اسم العميل مطلوب ولا يمكن أن يكون فارغاً');
      }
      final db = await databaseHelper.database;
      final id = await db.insert(_tableName, member.toMap());
      return id;
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('فشل في إضافة العميل: $e');
    }
  }

  @override
  Future<void> updateMember(MemberModel member) async {
    try {
      if (member.fullName.trim().isEmpty) {
        throw const DatabaseException('اسم العميل مطلوب ولا يمكن أن يكون فارغاً');
      }
      final db = await databaseHelper.database;

      // جلب رقم العضوية القديم للعميل لمعرفة ما إذا تم تغييره
      final oldMemberRows = await db.query(
        _tableName,
        columns: ['memberId'],
        where: 'id = ?',
        whereArgs: [member.id],
      );

      String? oldMemberId;
      if (oldMemberRows.isNotEmpty) {
        oldMemberId = oldMemberRows.first['memberId'] as String?;
      }

      final map = member.toMap();
      map.remove('id'); // لا نحدّث المفتاح الأساسي

      // تعطيل فحص المفاتيح الأجنبية خارج المعاملة (لأن SQLite يتجاهل الأمر داخل autocommit = false)
      await db.execute('PRAGMA foreign_keys = OFF;');
      try {
        await db.transaction((txn) async {
          final count = await txn.update(
            _tableName,
            map,
            where: 'id = ?',
            whereArgs: [member.id],
          );
          if (count == 0) {
            throw const DatabaseException('العميل غير موجود للتحديث');
          }

          // إذا تغير رقم العضوية، نحدث الجداول المرتبطة بالمعرف القديم
          if (oldMemberId != null &&
              oldMemberId.trim().isNotEmpty &&
              oldMemberId != member.memberId) {
            final newId = member.memberId;

            await txn.update(
              'attendance',
              {'memberId': newId},
              where: 'memberId = ?',
              whereArgs: [oldMemberId],
            );

            await txn.update(
              'payments',
              {'memberId': newId},
              where: 'memberId = ?',
              whereArgs: [oldMemberId],
            );

            await txn.update(
              'pos_sales',
              {'memberId': newId},
              where: 'memberId = ?',
              whereArgs: [oldMemberId],
            );
          }
        });
      } finally {
        await db.execute('PRAGMA foreign_keys = ON;');
      }
    } catch (e) {
      if (e is DatabaseException) rethrow;
      final errorMsg = e.toString();
      if (errorMsg.contains('UNIQUE') && errorMsg.contains('memberId')) {
        throw const DatabaseException('رقم العضوية (الكارت) مسجل لعميل آخر بالفعل');
      }
      if (errorMsg.contains('FOREIGN KEY')) {
        throw const DatabaseException('تعذر تحديث رقم العضوية لوجود بيانات مرتبطة به');
      }
      throw DatabaseException('فشل في تحديث بيانات العميل: $e');
    }
  }

  @override
  Future<void> deleteMember(int id) async {
    try {
      final db = await databaseHelper.database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException('العميل غير موجود للحذف');
      }
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('فشل في حذف العميل: $e');
    }
  }

  @override
  Future<List<MemberModel>> searchMembers(String query) async {
    try {
      final db = await databaseHelper.database;
      final searchQuery = '%$query%';
      final result = await db.query(
        _tableName,
        where: 'fullName LIKE ? OR phoneNumber LIKE ? OR memberId LIKE ?',
        whereArgs: [searchQuery, searchQuery, searchQuery],
        orderBy: 'createdAt DESC',
      );
      return result.map((map) => MemberModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في البحث عن العملاء: $e');
    }
  }
}
