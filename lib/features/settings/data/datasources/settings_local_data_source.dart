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
  static const _kDefaultA4Printer = 'default_a4_printer';
  static const _kWhatsappAccessToken = 'whatsapp_access_token';
  static const _kWhatsappPhoneNumberId = 'whatsapp_phone_number_id';

  @override
  Future<GymSettings> getSettings() async {
    final name = sharedPreferences.getString(_kGymName) ?? 'Sparta Gym';
    final phone = sharedPreferences.getString(_kGymPhone) ?? '';
    final address = sharedPreferences.getString(_kGymAddress) ?? '';
    final register = sharedPreferences.getString(_kGymRegister) ?? '';
    final theme = sharedPreferences.getString(_kThemeMode) ?? 'light';
    final logoPath = sharedPreferences.getString(_kLogoPath) ?? '';
    final defaultA4Printer = sharedPreferences.getString(_kDefaultA4Printer) ?? '';
    final whatsappAccessToken = sharedPreferences.getString(_kWhatsappAccessToken) ?? '';
    final whatsappPhoneNumberId = sharedPreferences.getString(_kWhatsappPhoneNumberId) ?? '';

    return GymSettings(
      gymName: name,
      gymPhone: phone,
      gymAddress: address,
      commercialRegister: register,
      themeMode: theme,
      logoPath: logoPath,
      defaultA4Printer: defaultA4Printer,
      whatsappAccessToken: whatsappAccessToken,
      whatsappPhoneNumberId: whatsappPhoneNumberId,
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
    await sharedPreferences.setString(_kDefaultA4Printer, settings.defaultA4Printer);
    await sharedPreferences.setString(_kWhatsappAccessToken, settings.whatsappAccessToken);
    await sharedPreferences.setString(_kWhatsappPhoneNumberId, settings.whatsappPhoneNumberId);
  }
}
