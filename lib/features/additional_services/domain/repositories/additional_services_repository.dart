import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/additional_service.dart';

abstract class AdditionalServicesRepository {
  Future<Either<Failure, List<AdditionalService>>> getAllServices();
  Future<Either<Failure, int>> addService(AdditionalService service);
  Future<Either<Failure, Unit>> updateService(AdditionalService service);
  Future<Either<Failure, Unit>> deleteService(int id);
}
