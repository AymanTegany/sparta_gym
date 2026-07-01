import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/additional_service.dart';
import '../../domain/repositories/additional_services_repository.dart';
import '../datasources/additional_services_local_data_source.dart';
import '../models/additional_service_model.dart';

class AdditionalServicesRepositoryImpl implements AdditionalServicesRepository {
  final AdditionalServicesLocalDataSource localDataSource;

  AdditionalServicesRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<AdditionalService>>> getAllServices() async {
    try {
      final services = await localDataSource.getAllServices();
      return right(services);
    } on DatabaseException catch (e) {
      return left(CacheFailure(e.message));
    } catch (e) {
      return left(CacheFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> addService(AdditionalService service) async {
    try {
      final model = AdditionalServiceModel.fromEntity(service);
      final id = await localDataSource.addService(model);
      return right(id);
    } on DatabaseException catch (e) {
      return left(CacheFailure(e.message));
    } catch (e) {
      return left(CacheFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateService(AdditionalService service) async {
    try {
      final model = AdditionalServiceModel.fromEntity(service);
      await localDataSource.updateService(model);
      return right(unit);
    } on DatabaseException catch (e) {
      return left(CacheFailure(e.message));
    } catch (e) {
      return left(CacheFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteService(int id) async {
    try {
      await localDataSource.deleteService(id);
      return right(unit);
    } on DatabaseException catch (e) {
      return left(CacheFailure(e.message));
    } catch (e) {
      return left(CacheFailure('حدث خطأ غير متوقع: $e'));
    }
  }
}
