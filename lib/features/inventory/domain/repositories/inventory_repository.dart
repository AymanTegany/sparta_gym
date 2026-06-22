import '../entities/inventory_item_entity.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getAllInventoryItems();
  Future<int> addInventoryItem(InventoryItem item);
  Future<int> deleteInventoryItem(int id);
}
