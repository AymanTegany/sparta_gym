import 'package:equatable/equatable.dart';
import '../../domain/entities/diet_plan.dart';

abstract class DietPlansState extends Equatable {
  const DietPlansState();

  @override
  List<Object> get props => [];
}

class DietPlansInitial extends DietPlansState {}

class DietPlansLoading extends DietPlansState {}

class DietPlansLoaded extends DietPlansState {
  final List<DietPlan> dietPlans;

  const DietPlansLoaded(this.dietPlans);

  @override
  List<Object> get props => [dietPlans];
}

class DietPlansError extends DietPlansState {
  final String message;

  const DietPlansError(this.message);

  @override
  List<Object> get props => [message];
}

class DietPlanOperationSuccess extends DietPlansState {
  final String message;

  const DietPlanOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
