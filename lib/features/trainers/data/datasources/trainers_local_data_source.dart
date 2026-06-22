import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/exception.dart';
import '../models/trainer_model.dart';

/// مصدر بيانات المدربين محلياً (Trainers Local Datasource)
abstract class TrainersLocalDataSource {
  Future<List<TrainerModel>> getAllTrainers();
  Future<int> addTrainer(TrainerModel trainer);
  Future<void> updateTrainer(TrainerModel trainer);
  Future<void> deleteTrainer(int id);
}

class TrainersLocalDataSourceImpl implements TrainersLocalDataSource {
  final DatabaseHelper databaseHelper;
  static const String _tableName = 'trainers';

  TrainersLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<TrainerModel>> getAllTrainers() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        _tableName,
        orderBy: 'id ASC',
      );
      return result.map((map) => TrainerModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('فشل في جلب المدربين: $e');
    }
  }

  @override
  Future<int> addTrainer(TrainerModel trainer) async {
    try {
      final db = await databaseHelper.database;
      return await db.insert(_tableName, trainer.toMap());
    } catch (e) {
      throw DatabaseException('فشل في إضافة المدرب: $e');
    }
  }

  @override
  Future<void> updateTrainer(TrainerModel trainer) async {
    try {
      final db = await databaseHelper.database;
      final count = await db.update(
        _tableName,
        trainer.toMap(),
        where: 'id = ?',
        whereArgs: [trainer.id],
      );
      if (count == 0) {
        throw const DatabaseException('المدرب غير موجود لتحديثه');
      }
    } catch (e) {
      throw DatabaseException('فشل في تحديث المدرب: $e');
    }
  }

  @override
  Future<void> deleteTrainer(int id) async {
    try {
      final db = await databaseHelper.database;
      final count = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw const DatabaseException('المدرب غير موجود لحذفه');
      }
    } catch (e) {
      throw DatabaseException('فشل في حذف المدرب: $e');
    }
  }
}
