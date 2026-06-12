import 'package:equatable/equatable.dart';
import '../../domain/entities/gym_settings_entity.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final GymSettings settings;
  final String? message;

  const SettingsLoaded({required this.settings, this.message});

  @override
  List<Object?> get props => [settings, message];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
