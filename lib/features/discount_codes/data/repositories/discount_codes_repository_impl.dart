import 'package:dartz/dartz.dart';

import '../../domain/entities/discount_code.dart';
import '../../domain/repositories/discount_codes_repository.dart';
import '../datasources/discount_codes_local_data_source.dart';
import '../models/discount_code_model.dart';

class DiscountCodesRepositoryImpl implements DiscountCodesRepository {
  final DiscountCodesLocalDataSource localDataSource;

  DiscountCodesRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<String, List<DiscountCode>>> getDiscountCodes() async {
    try {
      final discountCodes = await localDataSource.getDiscountCodes();
      return Right(discountCodes);
    } catch (e) {
      return Left('فشل في جلب أكواد الخصم: $e');
    }
  }

  @override
  Future<Either<String, void>> addDiscountCode(DiscountCode discountCode) async {
    try {
      final model = DiscountCodeModel.fromEntity(discountCode);
      await localDataSource.addDiscountCode(model);
      return const Right(null);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return const Left('اسم كود الخصم موجود بالفعل');
      }
      return Left('فشل في إضافة كود الخصم: $e');
    }
  }

  @override
  Future<Either<String, void>> updateDiscountCode(DiscountCode discountCode) async {
    try {
      final model = DiscountCodeModel.fromEntity(discountCode);
      await localDataSource.updateDiscountCode(model);
      return const Right(null);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return const Left('اسم كود الخصم موجود بالفعل');
      }
      return Left('فشل في تحديث كود الخصم: $e');
    }
  }

  @override
  Future<Either<String, void>> deleteDiscountCode(int id) async {
    try {
      await localDataSource.deleteDiscountCode(id);
      return const Right(null);
    } catch (e) {
      return Left('فشل في حذف كود الخصم: $e');
    }
  }
}
