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

  const GymSettings({
    required this.gymName,
    required this.gymPhone,
    required this.gymAddress,
    required this.commercialRegister,
    required this.themeMode,
    required this.logoPath,
    required this.defaultA4Printer,
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
  }) {
    return GymSettings(
      gymName: gymName ?? this.gymName,
      gymPhone: gymPhone ?? this.gymPhone,
      gymAddress: gymAddress ?? this.gymAddress,
      commercialRegister: commercialRegister ?? this.commercialRegister,
      themeMode: themeMode ?? this.themeMode,
      logoPath: logoPath ?? this.logoPath,
      defaultA4Printer: defaultA4Printer ?? this.defaultA4Printer,
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
      ];
}
