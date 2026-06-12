import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/gym_settings_entity.dart';

/// واجهة مستودع الإعدادات (Settings Repository Interface)
abstract class SettingsRepository {
  /// جلب إعدادات الجيم
  Future<Either<Failure, GymSettings>> getSettings();

  /// حفظ إعدادات الجيم
  Future<Either<Failure, void>> saveSettings(GymSettings settings);
}
