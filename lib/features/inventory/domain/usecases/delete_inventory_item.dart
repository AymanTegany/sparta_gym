import '../repositories/inventory_repository.dart';

class DeleteInventoryItemUseCase {
  final InventoryRepository repository;

  DeleteInventoryItemUseCase(this.repository);

  Future<int> call(int id) async {
    return await repository.deleteInventoryItem(id);
  }
}
