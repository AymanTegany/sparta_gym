import '../entities/pos_sale_entity.dart';
import '../entities/pos_sale_item_entity.dart';

abstract class PosRepository {
  Future<String> processSale({
    required PosSale sale,
    required List<PosSaleItem> items,
  });
}
