import 'package:dartz/dartz.dart';
import '../../../../core/errors/exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/report_stats.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_local_data_source.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsLocalDataSource localDataSource;

  ReportsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, ReportStats>> getReportStats(DateTime startDate, DateTime endDate) async {
    try {
      final stats = await localDataSource.getReportStats(startDate, endDate);
      return Right(stats);
    } on DatabaseException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('حدث خطأ غير متوقع أثناء جلب التقارير: $e'));
    }
  }
}
