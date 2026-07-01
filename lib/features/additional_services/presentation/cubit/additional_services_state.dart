import 'package:equatable/equatable.dart';
import '../../domain/entities/additional_service.dart';

abstract class AdditionalServicesState extends Equatable {
  const AdditionalServicesState();

  @override
  List<Object> get props => [];
}

class AdditionalServicesInitial extends AdditionalServicesState {}

class AdditionalServicesLoading extends AdditionalServicesState {}

class AdditionalServicesLoaded extends AdditionalServicesState {
  final List<AdditionalService> services;

  const AdditionalServicesLoaded({required this.services});

  @override
  List<Object> get props => [services];
}

class AdditionalServicesError extends AdditionalServicesState {
  final String message;

  const AdditionalServicesError({required this.message});

  @override
  List<Object> get props => [message];
}
