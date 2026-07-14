import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/members/presentation/cubit/members_cubit.dart';
import 'features/memberships/presentation/cubit/memberships_cubit.dart';
import 'features/attendance/presentation/cubit/attendance_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/settings/presentation/cubit/settings_state.dart';
import 'features/payments/presentation/cubit/payments_cubit.dart';
import 'features/home/presentation/cubit/dashboard_cubit.dart';
import 'features/trainers/presentation/cubit/trainers_cubit.dart';
import 'features/expenses/presentation/cubit/expenses_cubit.dart';
import 'features/inventory/presentation/cubit/inventory_cubit.dart';
import 'features/pos/presentation/cubit/pos_cubit.dart';
import 'features/diets/presentation/cubit/diet_plans_cubit.dart';
import 'features/reports/presentation/cubit/reports_cubit.dart';
import 'features/discount_codes/presentation/cubit/discount_codes_cubit.dart';
import 'features/shifts/presentation/cubit/shifts_cubit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'init_dependencies.dart';
import 'package:updat/updat_window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/services/github_update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة sqflite_ffi للعمل على Windows/Linux/macOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // تهيئة قاعدة البيانات
  await DatabaseHelper().database;

  // تهيئة حقن التبعيات
  await initDependencies();

  // تهيئة بيانات التاريخ والوقت
  await initializeDateFormatting('ar', null);

  // تهيئة معلومات الإصدار للتحديث التلقائي
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => serviceLocator<AuthCubit>()..checkSession(),
        ),
        BlocProvider<MembersCubit>(
          create: (_) => serviceLocator<MembersCubit>(),
        ),
        BlocProvider<MembershipsCubit>(
          create: (_) => serviceLocator<MembershipsCubit>(),
        ),
        BlocProvider<AttendanceCubit>(
          create: (_) => serviceLocator<AttendanceCubit>(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => serviceLocator<SettingsCubit>()..loadSettings(),
        ),
        BlocProvider<PaymentsCubit>(
          create: (_) => serviceLocator<PaymentsCubit>(),
        ),
        BlocProvider<DietPlansCubit>(
          create: (_) => serviceLocator<DietPlansCubit>(),
        ),
        BlocProvider<DashboardCubit>(
          create: (_) => serviceLocator<DashboardCubit>()..loadDashboard(),
        ),
        BlocProvider<TrainersCubit>(
          create: (_) => serviceLocator<TrainersCubit>(),
        ),
        BlocProvider<ExpensesCubit>(
          create: (_) => serviceLocator<ExpensesCubit>(),
        ),
        BlocProvider<InventoryCubit>(
          create: (_) => serviceLocator<InventoryCubit>(),
        ),
        BlocProvider<PosCubit>(create: (_) => serviceLocator<PosCubit>()),
        BlocProvider<ReportsCubit>(
          create: (_) => serviceLocator<ReportsCubit>(),
        ),
        BlocProvider<DiscountCodesCubit>(
          create: (_) => serviceLocator<DiscountCodesCubit>(),
        ),
        BlocProvider<ShiftsCubit>(
          lazy: false,
          create: (_) => serviceLocator<ShiftsCubit>()
            ..checkActiveShift()
            ..startScheduler(),
        ),
      ],
      child: SpartaGymApp(currentVersion: currentVersion),
    ),
  );
}

class SpartaGymApp extends StatelessWidget {
  final String currentVersion;
  
  const SpartaGymApp({super.key, required this.currentVersion});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        ThemeMode themeMode = ThemeMode.light;
        if (settingsState is SettingsLoaded) {
          themeMode = settingsState.settings.themeMode == 'light'
              ? ThemeMode.light
              : ThemeMode.dark;
        }

        return MaterialApp(
          builder: (context, child) {
            final updateService = GithubUpdateService(
              owner: 'AymanTegany', 
              repo: 'sparta-gym-releases'
            );
            return UpdatWindowManager(
              appName: 'Sparta Gym',
              currentVersion: currentVersion,
              getLatestVersion: updateService.getLatestVersion,
              getBinaryUrl: updateService.getBinaryUrl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          title: 'Sparta Gym',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          locale: const Locale('ar'),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthInitial || state is AuthLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (state is AuthAuthenticated) {
                return HomePage(
                  onThemeToggle: () {
                    context.read<SettingsCubit>().toggleTheme();
                  },
                  isDarkMode: themeMode == ThemeMode.dark,
                );
              }

              // في حال عدم تسجيل الدخول أو وجود خطأ
              return const LoginPage();
            },
          ),
        );
      },
    );
  }
}
