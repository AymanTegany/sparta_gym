import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/pos_sale_entity.dart';
import '../../domain/entities/pos_sale_item_entity.dart';

abstract class PosLocalDataSource {
  Future<String> processSale({
    required PosSale sale,
    required List<PosSaleItem> items,
  });
}

class PosLocalDataSourceImpl implements PosLocalDataSource {
  final DatabaseHelper databaseHelper;

  PosLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<String> processSale({
    required PosSale sale,
    required List<PosSaleItem> items,
  }) async {
    final db = await databaseHelper.database;
    
    // We use a transaction to ensure all operations succeed or fail together.
    await db.transaction((txn) async {
      // 1. Insert Sale
      final saleId = await txn.insert('pos_sales', sale.toMap());
      
      // 2. Insert Sale Items and update inventory
      for (final item in items) {
        final itemMap = item.toMap();
        itemMap['saleId'] = saleId; // Set the parent sale id
        await txn.insert('pos_sale_items', itemMap);
        
        // 3. Deduct quantity from inventory
        await txn.rawUpdate(
          'UPDATE inventory_items SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.itemId]
        );
      }
    });

    return sale.receiptId;
  }
}
