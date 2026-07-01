import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/additional_service.dart';
import '../../domain/usecases/additional_services_usecases.dart';
import 'additional_services_state.dart';

class AdditionalServicesCubit extends Cubit<AdditionalServicesState> {
  final GetAllAdditionalServices _getAllServices;
  final AddAdditionalService _addService;
  final UpdateAdditionalService _updateService;
  final DeleteAdditionalService _deleteService;

  AdditionalServicesCubit(
    this._getAllServices,
    this._addService,
    this._updateService,
    this._deleteService,
  ) : super(AdditionalServicesInitial());

  Future<void> loadServices() async {
    emit(AdditionalServicesLoading());
    final result = await _getAllServices(NoParams());
    result.fold(
      (failure) => emit(AdditionalServicesError(message: failure.message)),
      (services) => emit(AdditionalServicesLoaded(services: services)),
    );
  }

  Future<void> addService(AdditionalService service) async {
    final result = await _addService(service);
    result.fold(
      (failure) => emit(AdditionalServicesError(message: failure.message)),
      (_) => loadServices(),
    );
  }

  Future<void> updateService(AdditionalService service) async {
    final result = await _updateService(service);
    result.fold(
      (failure) => emit(AdditionalServicesError(message: failure.message)),
      (_) => loadServices(),
    );
  }

  Future<void> deleteService(int id) async {
    final result = await _deleteService(id);
    result.fold(
      (failure) => emit(AdditionalServicesError(message: failure.message)),
      (_) => loadServices(),
    );
  }
}
