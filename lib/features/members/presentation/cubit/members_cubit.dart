import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/usecases/add_member.dart';
import '../../domain/usecases/delete_member.dart';
import '../../domain/usecases/get_all_members.dart';
import '../../domain/usecases/search_members.dart';
import '../../domain/usecases/update_member.dart';
import 'members_state.dart';

/// Cubit لإدارة حالات العملاء.
/// يتعامل مع تحميل البيانات، البحث، الفلترة، والعمليات CRUD.
class MembersCubit extends Cubit<MembersState> {
  final GetAllMembers _getAllMembers;
  final AddMember _addMember;
  final UpdateMember _updateMember;
  final DeleteMember _deleteMember;
  final SearchMembers _searchMembers;

  Timer? _debounceTimer;

  MembersCubit({
    required GetAllMembers getAllMembers,
    required AddMember addMember,
    required UpdateMember updateMember,
    required DeleteMember deleteMember,
    required SearchMembers searchMembers,
  })  : _getAllMembers = getAllMembers,
        _addMember = addMember,
        _updateMember = updateMember,
        _deleteMember = deleteMember,
        _searchMembers = searchMembers,
        super(const MembersInitial());

  // ──────────────── تحميل العملاء ────────────────

  /// تحميل جميع العملاء من قاعدة البيانات
  Future<void> loadMembers() async {
    // عند التحديث مع وجود بيانات محملة مسبقاً، لا نعرض شاشة التحميل (تحديث صامت)
    final currentState = state;
    if (currentState is! MembersLoaded) {
      emit(const MembersLoading());
    }

    final result = await _getAllMembers(NoParams());

    result.fold(
      (failure) => emit(MembersError(failure.message)),
      (members) {
        final (:stats, :filterCounts) = _calculateStatsAndCounts(members);
        // الحفاظ على الفلتر والبحث الحاليين عند التحديث
        final filterType = currentState is MembersLoaded
            ? currentState.filterType
            : MemberFilterType.all;
        final searchQuery = currentState is MembersLoaded
            ? currentState.searchQuery
            : '';
        final displayedMembers = _applyFilter(members, filterType);
        emit(MembersLoaded(
          allMembers: members,
          displayedMembers: displayedMembers,
          stats: stats,
          filterType: filterType,
          searchQuery: searchQuery,
          filterCounts: filterCounts,
        ));
      },
    );
  }

  // ──────────────── البحث ────────────────

  /// بحث مباشر مع Debounce
  void searchMembers(String query) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().isEmpty) {
        // إعادة تحميل جميع البيانات بدون بحث
        _restoreFromSearch();
        return;
      }

      final currentState = state;
      if (currentState is! MembersLoaded) return;

      final result = await _searchMembers(query);

      result.fold(
        (failure) => emit(MembersError(failure.message)),
        (members) {
          final filteredMembers = _applyFilter(members, currentState.filterType);
          emit(currentState.copyWith(
            displayedMembers: filteredMembers,
            searchQuery: query,
          ));
        },
      );
    });
  }

  /// إعادة البيانات بعد مسح البحث
  void _restoreFromSearch() {
    final currentState = state;
    if (currentState is! MembersLoaded) return;

    final filteredMembers = _applyFilter(currentState.allMembers, currentState.filterType);
    emit(currentState.copyWith(
      displayedMembers: filteredMembers,
      searchQuery: '',
    ));
  }

  // ──────────────── الفلترة ────────────────

  /// تطبيق فلتر على العملاء
  void filterMembers(MemberFilterType filterType) {
    final currentState = state;
    if (currentState is! MembersLoaded) return;

    List<Member> sourceMembers = currentState.allMembers;

    // إذا كان هناك بحث نشط، نبحث أولاً ثم نفلتر
    if (currentState.searchQuery.isNotEmpty) {
      // في هذه الحالة نستخدم displayedMembers الحالية كمصدر
      // لكن الأفضل إعادة البحث مع الفلترة
      // لذلك نستخدم allMembers ونطبق الفلتر مباشرة
    }

    final filteredMembers = _applyFilter(sourceMembers, filterType);
    emit(currentState.copyWith(
      displayedMembers: filteredMembers,
      filterType: filterType,
    ));
  }

  /// تطبيق الفلتر على قائمة العملاء
  List<Member> _applyFilter(List<Member> members, MemberFilterType filterType) {
    switch (filterType) {
      case MemberFilterType.all:
        return members;
      case MemberFilterType.thisMonth:
        return members.where((m) => m.isThisMonth).toList();
      case MemberFilterType.active:
        return members.where((m) => m.isActive).toList();
      case MemberFilterType.expired:
        return members.where((m) => !m.isActive && m.membershipType != 'تمرينة واحدة').toList();
      case MemberFilterType.expiringSoon:
        return members.where((m) => m.isExpiringSoon).toList();
      case MemberFilterType.inDebt:
        return members.where((m) => m.hasDebt).toList();
      case MemberFilterType.singleSession:
        return members.where((m) => m.membershipType == 'تمرينة واحدة').toList();
    }
  }

  // ──────────────── العمليات CRUD ────────────────

  /// إضافة عميل جديد
  Future<bool> addMember(Member member, {bool refreshList = true}) async {
    final result = await _addMember(member);

    return result.fold(
      (failure) {
        emit(MembersError(failure.message));
        return false;
      },
      (id) {
        emit(const MemberActionSuccess('تم إضافة العميل بنجاح'));
        if (refreshList) {
          loadMembers(); // إعادة تحميل البيانات
        }
        return true;
      },
    );
  }

  /// تحديث بيانات عميل
  Future<bool> updateMember(Member member, {bool refreshList = true}) async {
    final result = await _updateMember(member);

    return result.fold(
      (failure) {
        emit(MembersError(failure.message));
        return false;
      },
      (_) {
        emit(const MemberActionSuccess('تم تحديث بيانات العميل بنجاح'));
        if (refreshList) {
          loadMembers();
        }
        return true;
      },
    );
  }

  /// حذف عميل
  Future<void> deleteMember(int id) async {
    final result = await _deleteMember(id);

    result.fold(
      (failure) => emit(MembersError(failure.message)),
      (_) {
        emit(const MemberActionSuccess('تم حذف العميل بنجاح'));
        loadMembers();
      },
    );
  }

  /// تجديد اشتراك عميل
  Future<bool> renewSubscription({
    required Member member,
    required String newMembershipType,
    required double newPrice,
    required double newDiscount,
    required double newPaidAmount,
    required String newStartDate,
    required String newEndDate,
    bool refreshList = true,
  }) async {
    final newRemainingAmount = (newPrice - newDiscount) - newPaidAmount;

    final updatedMember = Member(
      id: member.id,
      memberId: member.memberId,
      fullName: member.fullName,
      phoneNumber: member.phoneNumber,
      email: member.email,
      gender: member.gender,
      birthDate: member.birthDate,
      address: member.address,
      nationalId: member.nationalId,
      emergencyContact: member.emergencyContact,
      membershipType: newMembershipType,
      membershipPrice: newPrice,
      discount: newDiscount,
      paidAmount: newPaidAmount,
      remainingAmount: newRemainingAmount < 0 ? 0 : newRemainingAmount,
      startDate: newStartDate,
      endDate: newEndDate,
      trainerName: member.trainerName,
      notes: member.notes,
      memberPhotoPath: member.memberPhotoPath,
      dietPlanId: member.dietPlanId,
      createdAt: member.createdAt,
    );

    return await updateMember(updatedMember, refreshList: refreshList);
  }

  /// إضافة دفعة لعميل
  Future<void> addPayment({
    required Member member,
    required double amount,
  }) async {
    final newPaidAmount = member.paidAmount + amount;
    final newRemainingAmount = member.netPrice - newPaidAmount;

    final updatedMember = Member(
      id: member.id,
      memberId: member.memberId,
      fullName: member.fullName,
      phoneNumber: member.phoneNumber,
      email: member.email,
      gender: member.gender,
      birthDate: member.birthDate,
      address: member.address,
      nationalId: member.nationalId,
      emergencyContact: member.emergencyContact,
      membershipType: member.membershipType,
      membershipPrice: member.membershipPrice,
      discount: member.discount,
      paidAmount: newPaidAmount,
      remainingAmount: newRemainingAmount < 0 ? 0 : newRemainingAmount,
      startDate: member.startDate,
      endDate: member.endDate,
      trainerName: member.trainerName,
      notes: member.notes,
      memberPhotoPath: member.memberPhotoPath,
      createdAt: member.createdAt,
    );

    final result = await _updateMember(updatedMember);

    result.fold(
      (failure) => emit(MembersError(failure.message)),
      (_) {
        emit(const MemberActionSuccess('تم إضافة الدفعة بنجاح'));
        loadMembers();
      },
    );
  }

  /// حساب إحصائيات العملاء وعدد كل فلتر في مرور واحد على البيانات
  ({MembersStats stats, Map<MemberFilterType, int> filterCounts}) _calculateStatsAndCounts(List<Member> members) {
    int activeCount = 0;
    int expiredCount = 0;
    int thisMonthCount = 0;
    int expiringSoonCount = 0;
    int inDebtCount = 0;
    int singleSessionCount = 0;
    double monthlyRevenue = 0;

    for (final m in members) {
      final active = m.isActive;
      final isSingleSession = m.membershipType == 'تمرينة واحدة';

      if (active) {
        activeCount++;
        if (m.isExpiringSoon) expiringSoonCount++;
      } else if (!isSingleSession) {
        expiredCount++;
      }

      if (m.isThisMonth) {
        thisMonthCount++;
        monthlyRevenue += m.paidAmount;
      }

      if (m.hasDebt) inDebtCount++;
      if (isSingleSession) singleSessionCount++;
    }

    return (
      stats: MembersStats(
        totalMembers: members.length,
        activeMembers: activeCount,
        expiredMembers: expiredCount,
        monthlyRevenue: monthlyRevenue,
      ),
      filterCounts: {
        MemberFilterType.all: members.length,
        MemberFilterType.thisMonth: thisMonthCount,
        MemberFilterType.active: activeCount,
        MemberFilterType.expired: expiredCount,
        MemberFilterType.expiringSoon: expiringSoonCount,
        MemberFilterType.inDebt: inDebtCount,
        MemberFilterType.singleSession: singleSessionCount,
      },
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
