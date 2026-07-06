import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/add_payment.dart';
import '../../domain/usecases/get_payments_by_member.dart';
import '../../domain/usecases/get_all_payments.dart';
import '../../domain/usecases/get_payment_stats.dart';
import 'payments_state.dart';

class PaymentsCubit extends Cubit<PaymentsState> {
  final AddPaymentUseCase _addPayment;
  final GetPaymentsByMemberUseCase _getPaymentsByMember;
  final GetAllPaymentsUseCase _getAllPayments;
  final GetPaymentStatsUseCase _getPaymentStats;

  PaymentsCubit({
    required AddPaymentUseCase addPayment,
    required GetPaymentsByMemberUseCase getPaymentsByMember,
    required GetAllPaymentsUseCase getAllPayments,
    required GetPaymentStatsUseCase getPaymentStats,
  })  : _addPayment = addPayment,
        _getPaymentsByMember = getPaymentsByMember,
        _getAllPayments = getAllPayments,
        _getPaymentStats = getPaymentStats,
        super(PaymentsInitial());

  /// تحميل جميع سجلات المدفوعات والإحصائيات المالية
  Future<void> loadPaymentsAndStats() async {
    emit(PaymentsLoading());
    await _fetchDataAndEmit();
  }

  /// جلب مدفوعات عضو محدد
  Future<void> getMemberPayments(String memberId) async {
    List<Payment> all = [];
    Map<String, dynamic> statsMap = {
      'todayRevenue': 0.0,
      'monthRevenue': 0.0,
      'totalRevenue': 0.0,
      'totalDebts': 0.0,
    };

    if (state is PaymentsLoaded) {
      final loaded = state as PaymentsLoaded;
      all = loaded.allPayments;
      statsMap = loaded.stats;
    } else {
      final allRes = await _getAllPayments(NoParams());
      final statsRes = await _getPaymentStats(NoParams());
      allRes.fold((_) {}, (p) => all = p);
      statsRes.fold((_) {}, (s) => statsMap = s);
    }

    final result = await _getPaymentsByMember(memberId);
    result.fold(
      (failure) => emit(PaymentsError(failure.message)),
      (payments) {
        emit(PaymentsLoaded(
          allPayments: all,
          memberPayments: payments,
          stats: statsMap,
        ));
      },
    );
  }

  /// تسجيل عملية دفع جديدة
  Future<Payment?> recordPayment({
    required String memberId,
    required double amount,
    required String paymentMethod,
    required String employeeName,
    int? shiftId,
    String? notes,
  }) async {
    emit(PaymentsLoading());

    final now = DateTime.now();
    final receiptId = 'REC-${now.millisecondsSinceEpoch}';
    final paymentDate = now.toIso8601String();

    final payment = Payment(
      receiptId: receiptId,
      memberId: memberId,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentDate: paymentDate,
      employeeName: employeeName,
      shiftId: shiftId,
      notes: notes,
    );

    final result = await _addPayment(payment);
    return await result.fold(
      (failure) async {
        emit(PaymentsError(failure.message));
        await _fetchDataAndEmit();
        return null;
      },
      (savedPayment) async {
        emit(PaymentsActionSuccess(
          payment: savedPayment,
          message: 'تم تسجيل الدفعة بنجاح! رقم الإيصال: ${savedPayment.receiptId}',
        ));
        await _fetchDataAndEmit();
        return savedPayment;
      },
    );
  }

  /// جلب البيانات من المزودات ونشر حالة التحميل
  Future<void> _fetchDataAndEmit() async {
    List<Payment> existingMemberPayments = [];
    if (state is PaymentsLoaded) {
      existingMemberPayments = (state as PaymentsLoaded).memberPayments;
    }

    final allRes = await _getAllPayments(NoParams());
    final statsRes = await _getPaymentStats(NoParams());

    allRes.fold(
      (failure) => emit(PaymentsError(failure.message)),
      (payments) {
        statsRes.fold(
          (failure) => emit(PaymentsError(failure.message)),
          (statsMap) {
            emit(PaymentsLoaded(
              allPayments: payments,
              memberPayments: existingMemberPayments,
              stats: statsMap,
            ));
          },
        );
      },
    );
  }
}
