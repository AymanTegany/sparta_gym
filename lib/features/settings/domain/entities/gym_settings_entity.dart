import 'package:equatable/equatable.dart';

/// كائن إعدادات الجيم (Gym Settings Entity)
class GymSettings extends Equatable {
  final String gymName;
  final String gymPhone;
  final String gymAddress;
  final String commercialRegister;
  final String themeMode; // 'light' or 'dark'

  const GymSettings({
    required this.gymName,
    required this.gymPhone,
    required this.gymAddress,
    required this.commercialRegister,
    required this.themeMode,
  });

  /// قيم افتراضية للإعدادات عند أول تشغيل
  factory GymSettings.empty() {
    return const GymSettings(
      gymName: 'Sparta Gym',
      gymPhone: '',
      gymAddress: '',
      commercialRegister: '',
      themeMode: 'light',
    );
  }

  GymSettings copyWith({
    String? gymName,
    String? gymPhone,
    String? gymAddress,
    String? commercialRegister,
    String? themeMode,
  }) {
    return GymSettings(
      gymName: gymName ?? this.gymName,
      gymPhone: gymPhone ?? this.gymPhone,
      gymAddress: gymAddress ?? this.gymAddress,
      commercialRegister: commercialRegister ?? this.commercialRegister,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [
        gymName,
        gymPhone,
        gymAddress,
        commercialRegister,
        themeMode,
      ];
}
