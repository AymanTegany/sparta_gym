import '../../domain/entities/discount_code.dart';
import 'package:dartz/dartz.dart';

abstract class DiscountCodesRepository {
  Future<Either<String, List<DiscountCode>>> getDiscountCodes();
  Future<Either<String, void>> addDiscountCode(DiscountCode discountCode);
  Future<Either<String, void>> updateDiscountCode(DiscountCode discountCode);
  Future<Either<String, void>> deleteDiscountCode(int id);
}
