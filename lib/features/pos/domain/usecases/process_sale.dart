import '../entities/pos_sale_entity.dart';
import '../entities/pos_sale_item_entity.dart';
import '../repositories/pos_repository.dart';

class ProcessSaleUseCase {
  final PosRepository repository;

  ProcessSaleUseCase(this.repository);

  Future<String> call({required PosSale sale, required List<PosSaleItem> items}) async {
    return await repository.processSale(sale: sale, items: items);
  }
}
