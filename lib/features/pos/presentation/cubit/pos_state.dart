import 'package:equatable/equatable.dart';
import '../../../inventory/domain/entities/inventory_item_entity.dart';

abstract class PosState extends Equatable {
  const PosState();

  @override
  List<Object> get props => [];
}

class PosInitial extends PosState {}

class PosLoading extends PosState {}

class PosLoaded extends PosState {
  final List<InventoryItem> inventoryItems;
  final Map<int, int> cart; // Mapping from itemId to quantity

  const PosLoaded({required this.inventoryItems, required this.cart});

  @override
  List<Object> get props => [inventoryItems, cart];
}

class PosError extends PosState {
  final String message;

  const PosError(this.message);

  @override
  List<Object> get props => [message];
}
