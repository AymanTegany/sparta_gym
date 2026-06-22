import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_data_source.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource localDataSource;

  InventoryRepositoryImpl({required this.localDataSource});

  @override
  Future<List<InventoryItem>> getAllInventoryItems() async {
    return await localDataSource.getAllInventoryItems();
  }

  @override
  Future<int> addInventoryItem(InventoryItem item) async {
    return await localDataSource.addInventoryItem(item);
  }

  @override
  Future<int> deleteInventoryItem(int id) async {
    return await localDataSource.deleteInventoryItem(id);
  }
}
