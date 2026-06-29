import '../../../../core/database/database_helper.dart';
import '../models/discount_code_model.dart';

abstract class DiscountCodesLocalDataSource {
  Future<List<DiscountCodeModel>> getDiscountCodes();
  Future<void> addDiscountCode(DiscountCodeModel discountCode);
  Future<void> updateDiscountCode(DiscountCodeModel discountCode);
  Future<void> deleteDiscountCode(int id);
}

class DiscountCodesLocalDataSourceImpl implements DiscountCodesLocalDataSource {
  final DatabaseHelper databaseHelper;

  DiscountCodesLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<DiscountCodeModel>> getDiscountCodes() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('discount_codes', orderBy: 'id DESC');
    return List.generate(maps.length, (i) {
      return DiscountCodeModel.fromJson(maps[i]);
    });
  }

  @override
  Future<void> addDiscountCode(DiscountCodeModel discountCode) async {
    final db = await databaseHelper.database;
    await db.insert('discount_codes', discountCode.toJson());
  }

  @override
  Future<void> updateDiscountCode(DiscountCodeModel discountCode) async {
    final db = await databaseHelper.database;
    await db.update(
      'discount_codes',
      discountCode.toJson(),
      where: 'id = ?',
      whereArgs: [discountCode.id],
    );
  }

  @override
  Future<void> deleteDiscountCode(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'discount_codes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
