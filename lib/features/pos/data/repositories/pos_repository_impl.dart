import '../../domain/entities/pos_sale_entity.dart';
import '../../domain/entities/pos_sale_item_entity.dart';
import '../../domain/repositories/pos_repository.dart';
import '../datasources/pos_local_data_source.dart';

class PosRepositoryImpl implements PosRepository {
  final PosLocalDataSource localDataSource;

  PosRepositoryImpl({required this.localDataSource});

  @override
  Future<String> processSale({
    required PosSale sale,
    required List<PosSaleItem> items,
  }) async {
    return await localDataSource.processSale(sale: sale, items: items);
  }
}
