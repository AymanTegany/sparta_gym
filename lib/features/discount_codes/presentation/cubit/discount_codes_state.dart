import 'package:equatable/equatable.dart';
import '../../domain/entities/discount_code.dart';

abstract class DiscountCodesState extends Equatable {
  const DiscountCodesState();

  @override
  List<Object> get props => [];
}

class DiscountCodesInitial extends DiscountCodesState {}

class DiscountCodesLoading extends DiscountCodesState {}

class DiscountCodesLoaded extends DiscountCodesState {
  final List<DiscountCode> discountCodes;

  const DiscountCodesLoaded(this.discountCodes);

  @override
  List<Object> get props => [discountCodes];
}

class DiscountCodesError extends DiscountCodesState {
  final String message;

  const DiscountCodesError(this.message);

  @override
  List<Object> get props => [message];
}

class DiscountCodeActionSuccess extends DiscountCodesState {
  final String message;

  const DiscountCodeActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}
