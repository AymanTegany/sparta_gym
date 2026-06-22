import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseException;
import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/diet_plan_model.dart';

abstract class DietPlanLocalDataSource {
  Future<List<DietPlanModel>> getDietPlans();
  Future<DietPlanModel> getDietPlanById(int id);
  Future<int> addDietPlan(DietPlanModel dietPlan);
  Future<int> updateDietPlan(DietPlanModel dietPlan);
  Future<int> deleteDietPlan(int id);
}

class DietPlanLocalDataSourceImpl implements DietPlanLocalDataSource {
  final DatabaseHelper databaseHelper;

  DietPlanLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<int> addDietPlan(DietPlanModel dietPlan) async {
    try {
      final db = await databaseHelper.database;
      return await db.insert('diet_plans', dietPlan.toJson());
    } catch (e) {
      throw DatabaseException('فشل إضافة النظام الغذائي: $e');
    }
  }

  @override
  Future<int> deleteDietPlan(int id) async {
    try {
      final db = await databaseHelper.database;
      return await db.delete(
        'diet_plans',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('فشل حذف النظام الغذائي: $e');
    }
  }

  @override
  Future<DietPlanModel> getDietPlanById(int id) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        'diet_plans',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        return DietPlanModel.fromJson(result.first);
      } else {
        throw DatabaseException('النظام الغذائي غير موجود');
      }
    } catch (e) {
      throw DatabaseException('فشل جلب النظام الغذائي: $e');
    }
  }

  @override
  Future<List<DietPlanModel>> getDietPlans() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query('diet_plans', orderBy: 'id DESC');
      return result.map((json) => DietPlanModel.fromJson(json)).toList();
    } catch (e) {
      throw DatabaseException('فشل جلب الأنظمة الغذائية: $e');
    }
  }

  @override
  Future<int> updateDietPlan(DietPlanModel dietPlan) async {
    try {
      final db = await databaseHelper.database;
      return await db.update(
        'diet_plans',
        dietPlan.toJson(),
        where: 'id = ?',
        whereArgs: [dietPlan.id],
      );
    } catch (e) {
      throw DatabaseException('فشل تحديث النظام الغذائي: $e');
    }
  }
}
