import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository repository;

  SettingsCubit({required this.repository}) : super(SettingsInitial());

  /// تحميل الإعدادات عند فتح التطبيق
  Future<void> loadSettings() async {
    emit(SettingsLoading());
    final result = await repository.getSettings();
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (settings) => emit(SettingsLoaded(settings: settings)),
    );
  }

  /// حفظ بيانات الجيم
  Future<void> saveGymInfo({
    required String name,
    required String phone,
    required String address,
    required String register,
    String? logoPath,
  }) async {
    if (state is! SettingsLoaded) return;
    final currentSettings = (state as SettingsLoaded).settings;

    emit(SettingsLoading());

    final updated = currentSettings.copyWith(
      gymName: name,
      gymPhone: phone,
      gymAddress: address,
      commercialRegister: register,
      logoPath: logoPath ?? currentSettings.logoPath,
    );

    final result = await repository.saveSettings(updated);
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (_) => emit(SettingsLoaded(
        settings: updated,
        message: 'تم حفظ إعدادات الجيم بنجاح!',
      )),
    );
  }

  /// تبديل وحفظ الثيم (الوضع الليلي والنهاري)
  Future<void> toggleTheme() async {
    if (state is! SettingsLoaded) return;
    final currentSettings = (state as SettingsLoaded).settings;

    final newTheme = currentSettings.themeMode == 'light' ? 'dark' : 'light';
    final updated = currentSettings.copyWith(themeMode: newTheme);

    // تحديث فوري بدون حالة تحميل لمنع الفليكر (Flicker) في الواجهة
    final result = await repository.saveSettings(updated);
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (_) => emit(SettingsLoaded(settings: updated)),
    );
  }
}
