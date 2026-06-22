import 'package:equatable/equatable.dart';
import '../../domain/entities/trainer_entity.dart';

/// حالات إدارة المدربين (Trainers State)
abstract class TrainersState extends Equatable {
  const TrainersState();

  @override
  List<Object?> get props => [];
}

class TrainersInitial extends TrainersState {
  const TrainersInitial();
}

class TrainersLoading extends TrainersState {
  const TrainersLoading();
}

class TrainersLoaded extends TrainersState {
  final List<Trainer> trainers;

  const TrainersLoaded({required this.trainers});

  @override
  List<Object?> get props => [trainers];
}

class TrainersError extends TrainersState {
  final String message;

  const TrainersError(this.message);

  @override
  List<Object?> get props => [message];
}

class TrainerActionSuccess extends TrainersState {
  final String message;

  const TrainerActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
