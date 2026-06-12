import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/database_helper.dart';
import 'core/network/dio_client.dart';
import 'core/network/internet_connection_checker.dart';

// Auth Feature Imports
import 'features/auth/data/datasources/local_auth_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

// Members Feature Imports
import 'features/members/data/datasources/members_local_data_source.dart';
import 'features/members/data/repositories/members_repository_impl.dart';
import 'features/members/domain/repositories/members_repository.dart';
import 'features/members/domain/usecases/add_member.dart';
import 'features/members/domain/usecases/delete_member.dart';
import 'features/members/domain/usecases/get_all_members.dart';
import 'features/members/domain/usecases/get_member_by_id.dart';
import 'features/members/domain/usecases/search_members.dart';
import 'features/members/domain/usecases/update_member.dart';
import 'features/members/presentation/cubit/members_cubit.dart';

// Memberships Feature Imports
import 'features/memberships/data/datasources/memberships_local_data_source.dart';
import 'features/memberships/data/repositories/memberships_repository_impl.dart';
import 'features/memberships/domain/repositories/memberships_repository.dart';
import 'features/memberships/domain/usecases/add_membership.dart';
import 'features/memberships/domain/usecases/delete_membership.dart';
import 'features/memberships/domain/usecases/get_all_memberships.dart';
import 'features/memberships/domain/usecases/update_membership.dart';
import 'features/memberships/presentation/cubit/memberships_cubit.dart';

// Attendance Feature Imports
import 'features/attendance/data/datasources/attendance_local_data_source.dart';
import 'features/attendance/data/repositories/attendance_repository_impl.dart';
import 'features/attendance/domain/repositories/attendance_repository.dart';
import 'features/attendance/domain/usecases/check_in_member.dart';
import 'features/attendance/domain/usecases/check_out_member.dart';
import 'features/attendance/domain/usecases/get_daily_attendance.dart';
import 'features/attendance/domain/usecases/get_attendance_stats.dart';
import 'features/attendance/presentation/cubit/attendance_cubit.dart';

// Settings Feature Imports
import 'features/settings/data/datasources/settings_local_data_source.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

// Payments Feature Imports
import 'features/payments/data/datasources/payments_local_data_source.dart';
import 'features/payments/data/repositories/payments_repository_impl.dart';
import 'features/payments/domain/repositories/payments_repository.dart';
import 'features/payments/domain/usecases/add_payment.dart';
import 'features/payments/domain/usecases/get_all_payments.dart';
import 'features/payments/domain/usecases/get_payments_by_member.dart';
import 'features/payments/domain/usecases/get_payment_stats.dart';
import 'features/payments/presentation/cubit/payments_cubit.dart';

// Home Feature Imports
import 'features/home/data/datasources/home_local_data_source.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/presentation/cubit/dashboard_cubit.dart';

final serviceLocator = GetIt.instance;

/// تهيئة وحقن جميع التبعيات الخاصة بالتطبيق (Dependency Injection).
Future<void> initDependencies() async {
  // 1. Core & External Packages
  final sharedPreferences = await SharedPreferences.getInstance();
  serviceLocator.registerLazySingleton(() => sharedPreferences);
  
  serviceLocator.registerLazySingleton(() => Dio());
  
  // Database Helper (قاعدة البيانات المحلية)
  serviceLocator.registerLazySingleton(() => DatabaseHelper());

  // 2. Network Core
  serviceLocator.registerLazySingleton<DioClient>(
    () => DioClient(serviceLocator()),
  );
  
  serviceLocator.registerLazySingleton<ConnectionChecker>(
    () => ConnectionCheckerImpl(serviceLocator()),
  );

  // 3. Features
  _initAuth();
  _initMembers();
  _initMemberships();
  _initAttendance();
  _initSettings();
  _initPayments();
  _initHome();
}

/// تهيئة ميزة المصادقة والترخيص
void _initAuth() {
  // 1. Datasources
  serviceLocator.registerLazySingleton<LocalAuthDataSource>(
    () => LocalAuthDataSource(
      databaseHelper: serviceLocator(),
      prefs: serviceLocator(),
    ),
  );

  // 2. Repositories
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      localDataSource: serviceLocator(),
    ),
  );

  // 3. Cubit
  serviceLocator.registerFactory<AuthCubit>(
    () => AuthCubit(serviceLocator()),
  );
}

/// تهيئة ميزة إدارة العملاء
void _initMembers() {
  // 1. Datasources
  serviceLocator.registerLazySingleton<MembersLocalDataSource>(
    () => MembersLocalDataSourceImpl(
      databaseHelper: serviceLocator(),
    ),
  );

  // 2. Repositories
  serviceLocator.registerLazySingleton<MembersRepository>(
    () => MembersRepositoryImpl(
      localDataSource: serviceLocator(),
    ),
  );

  // 3. Usecases
  serviceLocator.registerLazySingleton(() => GetAllMembers(serviceLocator()));
  serviceLocator.registerLazySingleton(() => GetMemberById(serviceLocator()));
  serviceLocator.registerLazySingleton(() => AddMember(serviceLocator()));
  serviceLocator.registerLazySingleton(() => UpdateMember(serviceLocator()));
  serviceLocator.registerLazySingleton(() => DeleteMember(serviceLocator()));
  serviceLocator.registerLazySingleton(() => SearchMembers(serviceLocator()));

  // 4. Cubit
  serviceLocator.registerFactory<MembersCubit>(
    () => MembersCubit(
      getAllMembers: serviceLocator(),
      addMember: serviceLocator(),
      updateMember: serviceLocator(),
      deleteMember: serviceLocator(),
      searchMembers: serviceLocator(),
    ),
  );
}

/// تهيئة ميزة باقات الاشتراكات
void _initMemberships() {
  // 1. Datasources
  serviceLocator.registerLazySingleton<MembershipsLocalDataSource>(
    () => MembershipsLocalDataSourceImpl(
      databaseHelper: serviceLocator(),
    ),
  );

  // 2. Repositories
  serviceLocator.registerLazySingleton<MembershipsRepository>(
    () => MembershipsRepositoryImpl(
      localDataSource: serviceLocator(),
    ),
  );

  // 3. Usecases
  serviceLocator.registerLazySingleton(() => GetAllMemberships(serviceLocator()));
  serviceLocator.registerLazySingleton(() => AddMembership(serviceLocator()));
  serviceLocator.registerLazySingleton(() => UpdateMembership(serviceLocator()));
  serviceLocator.registerLazySingleton(() => DeleteMembership(serviceLocator()));

  // 4. Cubit
  serviceLocator.registerFactory<MembershipsCubit>(
    () => MembershipsCubit(
      getAllMemberships: serviceLocator(),
      addMembership: serviceLocator(),
      updateMembership: serviceLocator(),
      deleteMembership: serviceLocator(),
    ),
  );
}

/// تهيئة ميزة الحضور والانصراف
void _initAttendance() {
  // 1. Datasources
  serviceLocator.registerLazySingleton<AttendanceLocalDataSource>(
    () => AttendanceLocalDataSourceImpl(
      databaseHelper: serviceLocator(),
    ),
  );

  // 2. Repositories
  serviceLocator.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      localDataSource: serviceLocator(),
    ),
  );

  // 3. Usecases
  serviceLocator.registerLazySingleton(() => CheckInMemberUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => CheckOutMemberUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => GetDailyAttendanceUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => GetAttendanceStatsUseCase(serviceLocator()));

  // 4. Cubit
  serviceLocator.registerFactory<AttendanceCubit>(
    () => AttendanceCubit(
      checkInMember: serviceLocator(),
      checkOutMember: serviceLocator(),
      getDailyAttendance: serviceLocator(),
      getAttendanceStats: serviceLocator(),
      searchMembers: serviceLocator(),
    ),
  );
}

/// تهيئة ميزة الإعدادات
void _initSettings() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sharedPreferences: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Cubit
  serviceLocator.registerFactory<SettingsCubit>(
    () => SettingsCubit(repository: serviceLocator()),
  );
}

/// تهيئة ميزة المدفوعات والمالية
void _initPayments() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<PaymentsLocalDataSource>(
    () => PaymentsLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<PaymentsRepository>(
    () => PaymentsRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Usecases
  serviceLocator.registerLazySingleton(() => AddPaymentUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => GetPaymentsByMemberUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => GetAllPaymentsUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => GetPaymentStatsUseCase(serviceLocator()));

  // 4. Cubit
  serviceLocator.registerFactory<PaymentsCubit>(
    () => PaymentsCubit(
      addPayment: serviceLocator(),
      getPaymentsByMember: serviceLocator(),
      getAllPayments: serviceLocator(),
      getPaymentStats: serviceLocator(),
    ),
  );
}

/// تهيئة ميزة لوحة التحكم (Home)
void _initHome() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Cubit
  serviceLocator.registerFactory<DashboardCubit>(
    () => DashboardCubit(repository: serviceLocator()),
  );
}
