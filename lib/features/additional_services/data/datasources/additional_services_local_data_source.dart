import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/additional_service_model.dart';

abstract class AdditionalServicesLocalDataSource {
  Future<List<AdditionalServiceModel>> getAllServices();
  Future<int> addService(AdditionalServiceModel service);
  Future<void> updateService(AdditionalServiceModel service);
  Future<void> deleteService(int id);
}

class AdditionalServicesLocalDataSourceImpl implements AdditionalServicesLocalDataSource {
  final DatabaseHelper databaseHelper;

  AdditionalServicesLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<AdditionalServiceModel>> getAllServices() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'additional_services',
        orderBy: 'id DESC',
      );
      return maps.map((map) => AdditionalServiceModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب الخدمات الإضافية: $e');
    }
  }

  @override
  Future<int> addService(AdditionalServiceModel service) async {
    try {
      final db = await databaseHelper.database;
      final map = service.toMap();
      map.remove('id');
      return await db.insert('additional_services', map);
    } catch (e) {
      throw DatabaseException('فشل في إضافة الخدمة الإضافية: $e');
    }
  }

  @override
  Future<void> updateService(AdditionalServiceModel service) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        'additional_services',
        service.toMap(),
        where: 'id = ?',
        whereArgs: [service.id],
      );
    } catch (e) {
      throw DatabaseException('فشل في تحديث الخدمة الإضافية: $e');
    }
  }

  @override
  Future<void> deleteService(int id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        'additional_services',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('فشل في حذف الخدمة الإضافية: $e');
    }
  }
}
