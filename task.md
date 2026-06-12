# قائمة مهام تنفيذ ميزة الحضور والانصراف (Attendance)

## المرحلة 1: تحديث قاعدة البيانات (Database Setup)
- `[x]` تعديل `lib/core/database/database_helper.dart` لزيادة رقم الإصدار وإنشاء جدول `attendance` والفرس المساعدة في `_onCreate` و `_onUpgrade`.

## المرحلة 2: طبقة الـ Domain لميزة الحضور (Domain Layer)
- `[x]` إنشاء كيان الحضور `lib/features/attendance/domain/entities/attendance_entity.dart`
- `[x]` إنشاء واجهة المستودع `lib/features/attendance/domain/repositories/attendance_repository.dart`
- `[x]` إنشاء حالات الاستخدام الأربعة:
  - `[x]` `CheckInMember` في `lib/features/attendance/domain/usecases/check_in_member.dart`
  - `[x]` `CheckOutMember` في `lib/features/attendance/domain/usecases/check_out_member.dart`
  - `[x]` `GetDailyAttendance` في `lib/features/attendance/domain/usecases/get_daily_attendance.dart`
  - `[x]` `GetAttendanceStats` في `lib/features/attendance/domain/usecases/get_attendance_stats.dart`

## المرحلة 3: طبقة الـ Data لميزة الحضور (Data Layer)
- `[x]` إنشاء موديل الحضور `lib/features/attendance/data/models/attendance_model.dart`
- `[x]` إنشاء مصدر البيانات المحلي `lib/features/attendance/data/datasources/attendance_local_data_source.dart`
- `[x]` إنشاء تطبيق المستودع `lib/features/attendance/data/repositories/attendance_repository_impl.dart`

## المرحلة 4: طبقة الـ Presentation لميزة الحضور (Presentation Layer)
- `[x]` إنشاء الحالات والمتحكم (`attendance_state.dart` و `attendance_cubit.dart`)
- `[x]` إنشاء شاشة الحضور الرئيسية `lib/features/attendance/presentation/pages/attendance_page.dart`

## المرحلة 5: الدمج والربط (Integration & DI)
- `[x]` تعديل `lib/init_dependencies.dart` لتسجيل جميع الكلاسات والـ Cubit الخاص بالحضور.
- `[x]` تعديل `lib/main.dart` لإضافة الـ BlocProvider الخاص بالـ AttendanceCubit.
- `[x]` تعديل `lib/features/home/presentation/pages/home_page.dart` لإضافة زر الانتقال لشاشة الحضور.

## المرحلة 6: التحقق والتشغيل (Verification)
- `[x]` تشغيل `flutter analyze` للتأكد من خلو المشروع من أي تحذيرات أو أخطاء.
- `[/]` تشغيل `flutter build windows` للتأكد من نجاح عملية البناء والتصدير.
