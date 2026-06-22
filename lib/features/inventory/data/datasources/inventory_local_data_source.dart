import '../../../../../core/database/database_helper.dart';
import '../../domain/entities/inventory_item_entity.dart';

abstract class InventoryLocalDataSource {
  Future<List<InventoryItem>> getAllInventoryItems();
  Future<int> addInventoryItem(InventoryItem item);
  Future<int> deleteInventoryItem(int id);
}

class InventoryLocalDataSourceImpl implements InventoryLocalDataSource {
  final DatabaseHelper databaseHelper;

  InventoryLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<InventoryItem>> getAllInventoryItems() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('inventory_items', orderBy: 'id DESC');
    return List.generate(maps.length, (i) {
      return InventoryItem.fromMap(maps[i]);
    });
  }

  @override
  Future<int> addInventoryItem(InventoryItem item) async {
    final db = await databaseHelper.database;
    return await db.insert('inventory_items', item.toMap());
  }

  @override
  Future<int> deleteInventoryItem(int id) async {
    final db = await databaseHelper.database;
    return await db.delete(
      'inventory_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
