import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_item_entity.dart';
import '../../domain/usecases/get_all_inventory_items.dart';
import '../../domain/usecases/add_inventory_item.dart';
import '../../domain/usecases/delete_inventory_item.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final GetAllInventoryItemsUseCase getAllInventoryItems;
  final AddInventoryItemUseCase addInventoryItemUseCase;
  final DeleteInventoryItemUseCase deleteInventoryItemUseCase;

  InventoryCubit({
    required this.getAllInventoryItems,
    required this.addInventoryItemUseCase,
    required this.deleteInventoryItemUseCase,
  }) : super(InventoryInitial());

  Future<void> loadInventory() async {
    emit(InventoryLoading());
    try {
      final items = await getAllInventoryItems();
      emit(InventoryLoaded(items));
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    try {
      await addInventoryItemUseCase(item);
      loadInventory();
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    try {
      await deleteInventoryItemUseCase(id);
      loadInventory();
    } catch (e) {
      emit(InventoryError(e.toString()));
    }
  }
}
