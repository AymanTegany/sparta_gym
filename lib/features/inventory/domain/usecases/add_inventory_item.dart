import '../entities/inventory_item_entity.dart';
import '../repositories/inventory_repository.dart';

class AddInventoryItemUseCase {
  final InventoryRepository repository;

  AddInventoryItemUseCase(this.repository);

  Future<int> call(InventoryItem item) async {
    return await repository.addInventoryItem(item);
  }
}
