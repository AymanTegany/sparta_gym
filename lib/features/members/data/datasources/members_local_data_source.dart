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
      final db = await databaseHelper.database;
      final id = await db.insert(_tableName, member.toMap());
      return id;
    } catch (e) {
      throw DatabaseException('فشل في إضافة العميل: $e');
    }
  }

  @override
  Future<void> updateMember(MemberModel member) async {
    try {
      final db = await databaseHelper.database;
      final count = await db.update(
        _tableName,
        member.toMap(),
        where: 'id = ?',
        whereArgs: [member.id],
      );
      if (count == 0) {
        throw const DatabaseException('العميل غير موجود للتحديث');
      }
    } catch (e) {
      if (e is DatabaseException) rethrow;
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
