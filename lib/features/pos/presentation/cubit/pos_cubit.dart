import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/pos_sale_entity.dart';
import '../../domain/entities/pos_sale_item_entity.dart';
import '../../domain/usecases/process_sale.dart';
import '../../../inventory/domain/usecases/get_all_inventory_items.dart';
import '../../../inventory/domain/entities/inventory_item_entity.dart';
import 'pos_state.dart';

class PosCubit extends Cubit<PosState> {
  final ProcessSaleUseCase processSaleUseCase;
  final GetAllInventoryItemsUseCase getAllInventoryItems;

  PosCubit({
    required this.processSaleUseCase,
    required this.getAllInventoryItems,
  }) : super(PosInitial());

  Future<void> loadPos() async {
    emit(PosLoading());
    try {
      final items = await getAllInventoryItems();
      emit(PosLoaded(inventoryItems: items, cart: const {}));
    } catch (e) {
      emit(PosError(e.toString()));
    }
  }

  void addToCart(InventoryItem item) {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      final currentQuantityInCart = currentState.cart[item.id!] ?? 0;
      
      if (currentQuantityInCart < item.quantity) {
        final newCart = Map<int, int>.from(currentState.cart);
        newCart[item.id!] = currentQuantityInCart + 1;
        emit(PosLoaded(inventoryItems: currentState.inventoryItems, cart: newCart));
      }
    }
  }

  void removeFromCart(InventoryItem item) {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      final currentQuantityInCart = currentState.cart[item.id!] ?? 0;
      
      if (currentQuantityInCart > 0) {
        final newCart = Map<int, int>.from(currentState.cart);
        if (currentQuantityInCart == 1) {
          newCart.remove(item.id!);
        } else {
          newCart[item.id!] = currentQuantityInCart - 1;
        }
        emit(PosLoaded(inventoryItems: currentState.inventoryItems, cart: newCart));
      }
    }
  }

  Future<void> checkout(String paymentMethod, {int? shiftId}) async {
    if (state is PosLoaded) {
      final currentState = state as PosLoaded;
      if (currentState.cart.isEmpty) return;

      emit(PosLoading());
      try {
        double totalAmount = 0;
        List<PosSaleItem> saleItems = [];
        
        for (var entry in currentState.cart.entries) {
          final item = currentState.inventoryItems.firstWhere((e) => e.id == entry.key);
          final quantity = entry.value;
          final subtotal = item.price * quantity;
          totalAmount += subtotal;

          saleItems.add(PosSaleItem(
            saleId: 0, // Will be set by local data source
            itemId: item.id!,
            quantity: quantity,
            unitPrice: item.price,
            subtotal: subtotal,
          ));
        }

        final sale = PosSale(
          receiptId: 'REC-${DateTime.now().millisecondsSinceEpoch}',
          totalAmount: totalAmount,
          finalAmount: totalAmount,
          paymentMethod: paymentMethod,
          date: DateTime.now().toIso8601String().split('T').first,
          createdAt: DateTime.now().toIso8601String(),
          shiftId: shiftId,
        );

        await processSaleUseCase(sale: sale, items: saleItems);
        await loadPos(); // Reload to refresh inventory quantities and clear cart
      } catch (e) {
        emit(PosError(e.toString()));
      }
    }
  }
}
