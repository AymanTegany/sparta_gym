import '../entities/inventory_item_entity.dart';
import '../repositories/inventory_repository.dart';

class GetAllInventoryItemsUseCase {
  final InventoryRepository repository;

  GetAllInventoryItemsUseCase(this.repository);

  Future<List<InventoryItem>> call() async {
    return await repository.getAllInventoryItems();
  }
}
