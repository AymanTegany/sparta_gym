import 'package:equatable/equatable.dart';

/// كائن إعدادات الجيم (Gym Settings Entity)
class GymSettings extends Equatable {
  final String gymName;
  final String gymPhone;
  final String gymAddress;
  final String commercialRegister;
  final String themeMode; // 'light' or 'dark'
  final String logoPath;
  final String defaultA4Printer;
  final String whatsappAccessToken;
  final String whatsappPhoneNumberId;

  const GymSettings({
    required this.gymName,
    required this.gymPhone,
    required this.gymAddress,
    required this.commercialRegister,
    required this.themeMode,
    required this.logoPath,
    required this.defaultA4Printer,
    required this.whatsappAccessToken,
    required this.whatsappPhoneNumberId,
  });

  /// قيم افتراضية للإعدادات عند أول تشغيل
  factory GymSettings.empty() {
    return const GymSettings(
      gymName: 'Sparta Gym',
      gymPhone: '',
      gymAddress: '',
      commercialRegister: '',
      themeMode: 'light',
      logoPath: '',
      defaultA4Printer: '',
      whatsappAccessToken: '',
      whatsappPhoneNumberId: '',
    );
  }

  GymSettings copyWith({
    String? gymName,
    String? gymPhone,
    String? gymAddress,
    String? commercialRegister,
    String? themeMode,
    String? logoPath,
    String? defaultA4Printer,
    String? whatsappAccessToken,
    String? whatsappPhoneNumberId,
  }) {
    return GymSettings(
      gymName: gymName ?? this.gymName,
      gymPhone: gymPhone ?? this.gymPhone,
      gymAddress: gymAddress ?? this.gymAddress,
      commercialRegister: commercialRegister ?? this.commercialRegister,
      themeMode: themeMode ?? this.themeMode,
      logoPath: logoPath ?? this.logoPath,
      defaultA4Printer: defaultA4Printer ?? this.defaultA4Printer,
      whatsappAccessToken: whatsappAccessToken ?? this.whatsappAccessToken,
      whatsappPhoneNumberId: whatsappPhoneNumberId ?? this.whatsappPhoneNumberId,
    );
  }

  @override
  List<Object?> get props => [
        gymName,
        gymPhone,
        gymAddress,
        commercialRegister,
        themeMode,
        logoPath,
        defaultA4Printer,
        whatsappAccessToken,
        whatsappPhoneNumberId,
      ];
}
