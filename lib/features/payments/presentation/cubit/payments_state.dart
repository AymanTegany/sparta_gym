import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_entity.dart';

abstract class PaymentsState extends Equatable {
  const PaymentsState();

  @override
  List<Object?> get props => [];
}

class PaymentsInitial extends PaymentsState {}

class PaymentsLoading extends PaymentsState {}

class PaymentsLoaded extends PaymentsState {
  final List<Payment> allPayments;
  final List<Payment> memberPayments; // لمدفوعات عميل محدد
  final Map<String, dynamic> stats;
  final String? successMessage;

  const PaymentsLoaded({
    required this.allPayments,
    this.memberPayments = const [],
    required this.stats,
    this.successMessage,
  });

  PaymentsLoaded copyWith({
    List<Payment>? allPayments,
    List<Payment>? memberPayments,
    Map<String, dynamic>? stats,
    String? successMessage,
  }) {
    return PaymentsLoaded(
      allPayments: allPayments ?? this.allPayments,
      memberPayments: memberPayments ?? this.memberPayments,
      stats: stats ?? this.stats,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [allPayments, memberPayments, stats, successMessage];
}

class PaymentsActionSuccess extends PaymentsState {
  final Payment payment;
  final String message;

  const PaymentsActionSuccess({
    required this.payment,
    required this.message,
  });

  @override
  List<Object?> get props => [payment, message];
}

class PaymentsError extends PaymentsState {
  final String message;

  const PaymentsError(this.message);

  @override
  List<Object?> get props => [message];
}
