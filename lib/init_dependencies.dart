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

// Trainers Feature Imports
import 'features/trainers/data/datasources/trainers_local_data_source.dart';
import 'features/trainers/data/repositories/trainers_repository_impl.dart';
import 'features/trainers/domain/repositories/trainers_repository.dart';
import 'features/trainers/domain/usecases/add_trainer.dart';
import 'features/trainers/domain/usecases/delete_trainer.dart';
import 'features/trainers/domain/usecases/get_all_trainers.dart';
import 'features/trainers/domain/usecases/update_trainer.dart';
import 'features/trainers/presentation/cubit/trainers_cubit.dart';

// New Features Imports
import 'features/expenses/data/datasources/expenses_local_data_source.dart';
import 'features/expenses/data/repositories/expenses_repository_impl.dart';
import 'features/expenses/domain/repositories/expenses_repository.dart';
import 'features/expenses/domain/usecases/add_expense.dart';
import 'features/expenses/domain/usecases/delete_expense.dart';
import 'features/expenses/domain/usecases/get_all_expenses.dart';
import 'features/expenses/presentation/cubit/expenses_cubit.dart';
import 'features/inventory/data/datasources/inventory_local_data_source.dart';
import 'features/inventory/data/repositories/inventory_repository_impl.dart';
import 'features/inventory/domain/repositories/inventory_repository.dart';
import 'features/inventory/domain/usecases/add_inventory_item.dart';
import 'features/inventory/domain/usecases/delete_inventory_item.dart';
import 'features/inventory/domain/usecases/get_all_inventory_items.dart';
import 'features/inventory/presentation/cubit/inventory_cubit.dart';
import 'features/pos/data/datasources/pos_local_data_source.dart';
import 'features/pos/data/repositories/pos_repository_impl.dart';
import 'features/pos/domain/repositories/pos_repository.dart';
import 'features/pos/domain/usecases/process_sale.dart';
import 'features/pos/presentation/cubit/pos_cubit.dart';

// Diets Feature Imports
import 'features/diets/data/datasources/diet_plan_local_data_source.dart';
import 'features/diets/data/repositories/diet_plan_repository_impl.dart';
import 'features/diets/domain/repositories/diet_plan_repository.dart';
import 'features/diets/domain/usecases/add_diet_plan.dart';
import 'features/diets/domain/usecases/delete_diet_plan.dart';
import 'features/diets/domain/usecases/get_diet_plans.dart';
import 'features/diets/domain/usecases/update_diet_plan.dart';
import 'features/diets/presentation/cubit/diet_plans_cubit.dart';

// Reports Feature Imports
import 'features/reports/data/datasources/reports_local_data_source.dart';
import 'features/reports/data/repositories/reports_repository_impl.dart';
import 'features/reports/domain/repositories/reports_repository.dart';
import 'features/reports/presentation/cubit/reports_cubit.dart';

// Shifts Feature Imports
import 'features/shifts/data/datasources/shifts_local_data_source.dart';
import 'features/shifts/data/repositories/shifts_repository_impl.dart';
import 'features/shifts/domain/repositories/shifts_repository.dart';
import 'features/shifts/presentation/cubit/shifts_cubit.dart';

// Discount Codes Imports
import 'features/discount_codes/data/datasources/discount_codes_local_data_source.dart';
import 'features/discount_codes/data/repositories/discount_codes_repository_impl.dart';
import 'features/discount_codes/domain/repositories/discount_codes_repository.dart';
import 'features/discount_codes/presentation/cubit/discount_codes_cubit.dart';

// Additional Services Imports
import 'features/additional_services/data/datasources/additional_services_local_data_source.dart';
import 'features/additional_services/data/repositories/additional_services_repository_impl.dart';
import 'features/additional_services/domain/repositories/additional_services_repository.dart';
import 'features/additional_services/domain/usecases/additional_services_usecases.dart';
import 'features/additional_services/presentation/cubit/additional_services_cubit.dart';

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

  // 4. تهيئة ميزات التطبيق
  _initAuth();
  _initMembers();
  _initMemberships();
  _initAttendance();
  _initSettings();
  _initPayments();
  _initHome();
  _initTrainers();
  _initExpenses();
  _initInventory();
  _initPos();
  _initDiets();
  _initReports();
  _initDiscountCodes();
  _initAdditionalServices();
  _initShifts();
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

/// تهيئة ميزة أكواد الخصم
void _initDiscountCodes() {
  // 1. Datasources
  serviceLocator.registerLazySingleton<DiscountCodesLocalDataSource>(
    () => DiscountCodesLocalDataSourceImpl(
      databaseHelper: serviceLocator(),
    ),
  );

  // 2. Repositories
  serviceLocator.registerLazySingleton<DiscountCodesRepository>(
    () => DiscountCodesRepositoryImpl(
      localDataSource: serviceLocator(),
    ),
  );

  // 3. Cubit
  serviceLocator.registerFactory<DiscountCodesCubit>(
    () => DiscountCodesCubit(
      repository: serviceLocator(),
    ),
  );
}

void _initAdditionalServices() {
  serviceLocator.registerLazySingleton<AdditionalServicesLocalDataSource>(
    () => AdditionalServicesLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  serviceLocator.registerLazySingleton<AdditionalServicesRepository>(
    () => AdditionalServicesRepositoryImpl(localDataSource: serviceLocator()),
  );

  serviceLocator.registerLazySingleton(() => GetAllAdditionalServices(serviceLocator()));
  serviceLocator.registerLazySingleton(() => AddAdditionalService(serviceLocator()));
  serviceLocator.registerLazySingleton(() => UpdateAdditionalService(serviceLocator()));
  serviceLocator.registerLazySingleton(() => DeleteAdditionalService(serviceLocator()));

  serviceLocator.registerFactory(() => AdditionalServicesCubit(
    serviceLocator(),
    serviceLocator(),
    serviceLocator(),
    serviceLocator(),
  ));
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

/// تهيئة ميزة إدارة المدربين
void _initTrainers() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<TrainersLocalDataSource>(
    () => TrainersLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<TrainersRepository>(
    () => TrainersRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Usecases
  serviceLocator.registerLazySingleton(() => GetAllTrainers(serviceLocator()));
  serviceLocator.registerLazySingleton(() => AddTrainer(serviceLocator()));
  serviceLocator.registerLazySingleton(() => UpdateTrainer(serviceLocator()));
  serviceLocator.registerLazySingleton(() => DeleteTrainer(serviceLocator()));

  // 4. Cubit
  serviceLocator.registerFactory<TrainersCubit>(
    () => TrainersCubit(
      getAllTrainers: serviceLocator(),
      addTrainer: serviceLocator(),
      updateTrainer: serviceLocator(),
      deleteTrainer: serviceLocator(),
    ),
  );
}

void _initExpenses() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<ExpensesLocalDataSource>(
    () => ExpensesLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<ExpensesRepository>(
    () => ExpensesRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Usecases
  serviceLocator.registerLazySingleton(() => GetAllExpensesUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => AddExpenseUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => DeleteExpenseUseCase(serviceLocator()));

  // 4. Cubit
  serviceLocator.registerFactory<ExpensesCubit>(
    () => ExpensesCubit(
      getAllExpenses: serviceLocator(),
      addExpenseUseCase: serviceLocator(),
      deleteExpenseUseCase: serviceLocator(),
    ),
  );
}

void _initInventory() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<InventoryLocalDataSource>(
    () => InventoryLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Usecases
  serviceLocator.registerLazySingleton(() => GetAllInventoryItemsUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => AddInventoryItemUseCase(serviceLocator()));
  serviceLocator.registerLazySingleton(() => DeleteInventoryItemUseCase(serviceLocator()));

  // 4. Cubit
  serviceLocator.registerFactory<InventoryCubit>(
    () => InventoryCubit(
      getAllInventoryItems: serviceLocator(),
      addInventoryItemUseCase: serviceLocator(),
      deleteInventoryItemUseCase: serviceLocator(),
    ),
  );
}

void _initPos() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<PosLocalDataSource>(
    () => PosLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<PosRepository>(
    () => PosRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Usecases
  serviceLocator.registerLazySingleton(() => ProcessSaleUseCase(serviceLocator()));

  // 4. Cubit
  serviceLocator.registerFactory<PosCubit>(
    () => PosCubit(
      processSaleUseCase: serviceLocator(),
      getAllInventoryItems: serviceLocator(), // We reuse this from Inventory
    ),
  );
}

/// تهيئة ميزة الأنظمة الغذائية
void _initDiets() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<DietPlanLocalDataSource>(
    () => DietPlanLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<DietPlanRepository>(
    () => DietPlanRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Usecases
  serviceLocator.registerLazySingleton(() => GetDietPlans(serviceLocator()));
  serviceLocator.registerLazySingleton(() => AddDietPlan(serviceLocator()));
  serviceLocator.registerLazySingleton(() => UpdateDietPlan(serviceLocator()));
  serviceLocator.registerLazySingleton(() => DeleteDietPlan(serviceLocator()));

  // 4. Cubit
  serviceLocator.registerFactory<DietPlansCubit>(
    () => DietPlansCubit(
      getDietPlans: serviceLocator(),
      addDietPlan: serviceLocator(),
      updateDietPlan: serviceLocator(),
      deleteDietPlan: serviceLocator(),
    ),
  );
}

/// تهيئة ميزة التقارير اليومية
void _initReports() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<ReportsLocalDataSource>(
    () => ReportsLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Cubit
  serviceLocator.registerFactory<ReportsCubit>(
    () => ReportsCubit(repository: serviceLocator()),
  );
}

/// تهيئة ميزة الشفتات
void _initShifts() {
  // 1. Datasource
  serviceLocator.registerLazySingleton<ShiftsLocalDataSource>(
    () => ShiftsLocalDataSourceImpl(databaseHelper: serviceLocator()),
  );

  // 2. Repository
  serviceLocator.registerLazySingleton<ShiftsRepository>(
    () => ShiftsRepositoryImpl(localDataSource: serviceLocator()),
  );

  // 3. Cubit
  serviceLocator.registerFactory<ShiftsCubit>(
    () => ShiftsCubit(repository: serviceLocator()),
  );
}
