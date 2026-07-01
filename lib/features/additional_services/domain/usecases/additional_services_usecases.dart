import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/additional_service.dart';
import '../repositories/additional_services_repository.dart';

class GetAllAdditionalServices implements UseCase<List<AdditionalService>, NoParams> {
  final AdditionalServicesRepository repository;

  GetAllAdditionalServices(this.repository);

  @override
  Future<Either<Failure, List<AdditionalService>>> call(NoParams params) async {
    return await repository.getAllServices();
  }
}

class AddAdditionalService implements UseCase<int, AdditionalService> {
  final AdditionalServicesRepository repository;

  AddAdditionalService(this.repository);

  @override
  Future<Either<Failure, int>> call(AdditionalService params) async {
    return await repository.addService(params);
  }
}

class UpdateAdditionalService implements UseCase<Unit, AdditionalService> {
  final AdditionalServicesRepository repository;

  UpdateAdditionalService(this.repository);

  @override
  Future<Either<Failure, Unit>> call(AdditionalService params) async {
    return await repository.updateService(params);
  }
}

class DeleteAdditionalService implements UseCase<Unit, int> {
  final AdditionalServicesRepository repository;

  DeleteAdditionalService(this.repository);

  @override
  Future<Either<Failure, Unit>> call(int params) async {
    return await repository.deleteService(params);
  }
}
