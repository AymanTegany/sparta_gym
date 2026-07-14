import 'package:flutter/foundation.dart';
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

  /// قفل لمنع تشغيل أكثر من عملية مسح في نفس الوقت
  bool _isProcessing = false;

  /// حماية من تكرار نفس الباركود في فترة قصيرة (Cooldown)
  String? _lastProcessedBarcode;
  DateTime? _lastProcessedTime;
  static const int _cooldownSeconds = 3;

  /// التحقق مما إذا كان الباركود مكرراً في فترة الحماية
  bool _isDuplicate(String barcodeOrPhone) {
    final now = DateTime.now();
    if (_lastProcessedBarcode == barcodeOrPhone.trim() &&
        _lastProcessedTime != null &&
        now.difference(_lastProcessedTime!).inSeconds < _cooldownSeconds) {
      debugPrint('[AttendanceCubit] تجاهل باركود مكرر: $barcodeOrPhone (خلال $_cooldownSeconds ثواني)');
      return true;
    }
    return false;
  }

  /// تسجيل الباركود كآخر باركود تم معالجته
  void _markProcessed(String barcodeOrPhone) {
    _lastProcessedBarcode = barcodeOrPhone.trim();
    _lastProcessedTime = DateTime.now();
  }

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

    // منع المسح المتزامن: إذا كانت عملية مسح جارية بالفعل، نتجاهل هذا المسح
    if (_isProcessing) {
      debugPrint('[AttendanceCubit] تجاهل مسح متزامن: عملية جارية بالفعل');
      return;
    }

    // منع تكرار نفس الباركود في فترة قصيرة
    if (_isDuplicate(barcodeOrPhone)) return;

    _isProcessing = true;
    _markProcessed(barcodeOrPhone);

    try {
      if (mode == 'دخول') {
        await _doCheckIn(barcodeOrPhone);
      } else if (mode == 'خروج') {
        await _doCheckOut(barcodeOrPhone);
      } else {
        // وضع تلقائي: التحقق مما إذا كان العضو مسجلاً دخولاً حالياً ولم يسجل خروجاً
        bool isAlreadyIn = false;
        final result = await _checkIfCheckedIn(barcodeOrPhone.trim());
        result.fold(
          (failure) => isAlreadyIn = false,
          (checkedIn) => isAlreadyIn = checkedIn,
        );
        
        if (isAlreadyIn) {
          await _doCheckOut(barcodeOrPhone);
        } else {
          await _doCheckIn(barcodeOrPhone);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// تسجيل حضور (واجهة عامة للبحث اليدوي)
  Future<void> checkIn(String barcodeOrPhone) async {
    if (barcodeOrPhone.trim().isEmpty) return;
    if (_isProcessing) return;
    if (_isDuplicate(barcodeOrPhone)) return;
    _isProcessing = true;
    _markProcessed(barcodeOrPhone);
    try {
      await _doCheckIn(barcodeOrPhone);
    } finally {
      _isProcessing = false;
    }
  }

  /// تسجيل انصراف (واجهة عامة للبحث اليدوي)
  Future<void> checkOut(String barcodeOrPhone) async {
    if (barcodeOrPhone.trim().isEmpty) return;
    if (_isProcessing) return;
    if (_isDuplicate(barcodeOrPhone)) return;
    _isProcessing = true;
    _markProcessed(barcodeOrPhone);
    try {
      await _doCheckOut(barcodeOrPhone);
    } finally {
      _isProcessing = false;
    }
  }

  /// التنفيذ الداخلي لتسجيل الحضور (بدون قفل - القفل يتم في الدوال العامة)
  Future<void> _doCheckIn(String barcodeOrPhone) async {
    // إنهاء أي جلسات معلقة قديمة (مثل حضور أمس بدون تسجيل خروج) قبل محاولة تسجيل الدخول
    await _autoCheckoutOutdated(6);

    // لا نرسل AttendanceLoading هنا حتى لا يختفي الجدول أثناء المعالجة
    final result = await _checkInMember(barcodeOrPhone.trim());
    
    // التحقق من أن الكيوبت لم يُغلق أثناء العملية
    if (isClosed) return;

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

  /// التنفيذ الداخلي لتسجيل الانصراف (بدون قفل - القفل يتم في الدوال العامة)
  Future<void> _doCheckOut(String barcodeOrPhone) async {
    // لا نرسل AttendanceLoading هنا حتى لا يختفي الجدول أثناء المعالجة
    final result = await _checkOutMember(barcodeOrPhone.trim());

    // التحقق من أن الكيوبت لم يُغلق أثناء العملية
    if (isClosed) return;

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
    if (isClosed) return;

    List<Member> existingSearch = [];
    if (state is AttendanceLoaded) {
      existingSearch = (state as AttendanceLoaded).searchResults;
    }

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // تسجيل الخروج التلقائي بعد 6 ساعات
      await _autoCheckoutOutdated(6);

      if (isClosed) return;

      final dailyResult = await _getDailyAttendance(dateStr);
      final statsResult = await _getAttendanceStats(NoParams());

      if (isClosed) return;

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
    } catch (e) {
      debugPrint('[AttendanceCubit] خطأ في _fetchDailyDataAndEmit: $e');
      if (!isClosed) {
        emit(AttendanceError('فشل في تحديث البيانات: $e'));
      }
    }
  }
}
