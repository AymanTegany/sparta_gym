import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/gym_settings_entity.dart';

abstract class SettingsLocalDataSource {
  Future<GymSettings> getSettings();
  Future<void> saveSettings(GymSettings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences sharedPreferences;

  SettingsLocalDataSourceImpl({required this.sharedPreferences});

  static const _kGymName = 'gym_name';
  static const _kGymPhone = 'gym_phone';
  static const _kGymAddress = 'gym_address';
  static const _kGymRegister = 'gym_register';
  static const _kThemeMode = 'theme_mode';
  static const _kLogoPath = 'logo_path';

  @override
  Future<GymSettings> getSettings() async {
    final name = sharedPreferences.getString(_kGymName) ?? 'Sparta Gym';
    final phone = sharedPreferences.getString(_kGymPhone) ?? '';
    final address = sharedPreferences.getString(_kGymAddress) ?? '';
    final register = sharedPreferences.getString(_kGymRegister) ?? '';
    final theme = sharedPreferences.getString(_kThemeMode) ?? 'light';
    final logoPath = sharedPreferences.getString(_kLogoPath) ?? '';

    return GymSettings(
      gymName: name,
      gymPhone: phone,
      gymAddress: address,
      commercialRegister: register,
      themeMode: theme,
      logoPath: logoPath,
    );
  }

  @override
  Future<void> saveSettings(GymSettings settings) async {
    await sharedPreferences.setString(_kGymName, settings.gymName);
    await sharedPreferences.setString(_kGymPhone, settings.gymPhone);
    await sharedPreferences.setString(_kGymAddress, settings.gymAddress);
    await sharedPreferences.setString(_kGymRegister, settings.commercialRegister);
    await sharedPreferences.setString(_kThemeMode, settings.themeMode);
    await sharedPreferences.setString(_kLogoPath, settings.logoPath);
  }
}
