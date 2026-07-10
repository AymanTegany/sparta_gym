import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../members/domain/entities/member_entity.dart';
import '../../../members/domain/usecases/search_members.dart';
import '../../domain/usecases/check_in_member.dart';
import '../../domain/usecases/check_out_member.dart';
import '../../domain/usecases/get_daily_attendance.dart';
import '../../domain/usecases/get_attendance_stats.dart';
import '../../domain/usecases/auto_checkout_outdated.dart';
import '../../domain/usecases/check_if_checked_in.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  final CheckInMemberUseCase _checkInMember;
  final CheckOutMemberUseCase _checkOutMember;
  final GetDailyAttendanceUseCase _getDailyAttendance;
  final GetAttendanceStatsUseCase _getAttendanceStats;
  final SearchMembers _searchMembers;
  final AutoCheckoutOutdatedUseCase _autoCheckoutOutdated;
  final CheckIfCheckedInUseCase _checkIfCheckedIn;

  AttendanceCubit({
    required CheckInMemberUseCase checkInMember,
    required CheckOutMemberUseCase checkOutMember,
    required GetDailyAttendanceUseCase getDailyAttendance,
    required GetAttendanceStatsUseCase getAttendanceStats,
    required SearchMembers searchMembers,
    required AutoCheckoutOutdatedUseCase autoCheckoutOutdated,
    required CheckIfCheckedInUseCase checkIfCheckedIn,
  })  : _checkInMember = checkInMember,
        _checkOutMember = checkOutMember,
        _getDailyAttendance = getDailyAttendance,
        _getAttendanceStats = getAttendanceStats,
        _searchMembers = searchMembers,
        _autoCheckoutOutdated = autoCheckoutOutdated,
        _checkIfCheckedIn = checkIfCheckedIn,
        super(AttendanceInitial());

  /// تحميل سجل حضور اليوم والإحصائيات
  Future<void> loadDailyData() async {
    emit(AttendanceLoading());
    await _fetchDailyDataAndEmit();
  }

  /// بحث عن الأعضاء يدوياً
  Future<void> search(String query) async {
    if (state is! AttendanceLoaded) return;
    final currentState = state as AttendanceLoaded;

    if (query.trim().isEmpty) {
      emit(currentState.copyWith(searchResults: []));
      return;
    }

    final result = await _searchMembers(query.trim());
    result.fold(
      (failure) {}, // لا نغير الحالة في حال الفشل
      (members) {
        emit(currentState.copyWith(searchResults: members));
      },
    );
  }

  /// معالجة عملية المسح بناءً على الوضع المختار
  Future<void> processScan(String barcodeOrPhone, String mode) async {
    if (barcodeOrPhone.trim().isEmpty) return;

    if (mode == 'دخول') {
      await checkIn(barcodeOrPhone);
    } else if (mode == 'خروج') {
      await checkOut(barcodeOrPhone);
    } else {
      // وضع تلقائي: التحقق مما إذا كان العضو مسجلاً دخولاً حالياً ولم يسجل خروجاً
      bool isAlreadyIn = false;
      final result = await _checkIfCheckedIn(barcodeOrPhone.trim());
      result.fold(
        (failure) => isAlreadyIn = false,
        (checkedIn) => isAlreadyIn = checkedIn,
      );
      
      if (isAlreadyIn) {
        await checkOut(barcodeOrPhone);
      } else {
        await checkIn(barcodeOrPhone);
      }
    }
  }

  /// تسجيل حضور
  Future<void> checkIn(String barcodeOrPhone) async {
    if (barcodeOrPhone.trim().isEmpty) return;
    
    emit(AttendanceLoading());
    final result = await _checkInMember(barcodeOrPhone.trim());
    
    await result.fold(
      (failure) async {
        emit(AttendanceError(failure.message));
        await _fetchDailyDataAndEmit();
      },
      (attendance) async {
        final message = 'تم تسجيل دخول العضو "${attendance.memberName}" بنجاح!';
        emit(AttendanceActionSuccess(
          attendance: attendance,
          type: 'حضور',
          message: message,
        ));
        await _fetchDailyDataAndEmit();
      },
    );
  }

  /// تسجيل انصراف
  Future<void> checkOut(String barcodeOrPhone) async {
    if (barcodeOrPhone.trim().isEmpty) return;

    emit(AttendanceLoading());
    final result = await _checkOutMember(barcodeOrPhone.trim());

    await result.fold(
      (failure) async {
        emit(AttendanceError(failure.message));
        await _fetchDailyDataAndEmit();
      },
      (attendance) async {
        final duration = attendance.durationMinutes ?? 0;
        final message = 'تم تسجيل خروج العضو "${attendance.memberName}" بنجاح! مدة التمرين: $duration دقيقة.';
        emit(AttendanceActionSuccess(
          attendance: attendance,
          type: 'انصراف',
          message: message,
        ));
        await _fetchDailyDataAndEmit();
      },
    );
  }

  /// جلب البيانات المحدثة وإرسال الحالة المحملة مع الحفاظ على نتائج البحث الحالية
  Future<void> _fetchDailyDataAndEmit() async {
    List<Member> existingSearch = [];
    if (state is AttendanceLoaded) {
      existingSearch = (state as AttendanceLoaded).searchResults;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // تسجيل الخروج التلقائي بعد 6 ساعات
    await _autoCheckoutOutdated(6);

    final dailyResult = await _getDailyAttendance(dateStr);
    final statsResult = await _getAttendanceStats(NoParams());

    dailyResult.fold(
      (failure) => emit(AttendanceError(failure.message)),
      (dailyList) {
        statsResult.fold(
          (failure) => emit(AttendanceError(failure.message)),
          (statsMap) {
            emit(AttendanceLoaded(
              dailyAttendance: dailyList,
              stats: statsMap,
              searchResults: existingSearch,
            ));
          },
        );
      },
    );
  }
}
