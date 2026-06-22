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
    emit(const MembersLoading());

    final result = await _getAllMembers(NoParams());

    result.fold(
      (failure) => emit(MembersError(failure.message)),
      (members) {
        final stats = _calculateStats(members);
        emit(MembersLoaded(
          allMembers: members,
          displayedMembers: members,
          stats: stats,
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
      case MemberFilterType.active:
        return members.where((m) => m.isActive).toList();
      case MemberFilterType.expired:
        return members.where((m) => !m.isActive).toList();
      case MemberFilterType.expiringSoon:
        return members.where((m) => m.isExpiringSoon).toList();
      case MemberFilterType.inDebt:
        return members.where((m) => m.hasDebt).toList();
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

  // ──────────────── حساب الإحصائيات ────────────────

  /// حساب إحصائيات العملاء
  MembersStats _calculateStats(List<Member> members) {
    final totalMembers = members.length;
    final activeMembers = members.where((m) => m.isActive).length;
    final expiredMembers = members.where((m) => !m.isActive).length;

    // حساب الإيرادات الشهرية (مجموع المدفوعات للأعضاء الذين بدأوا هذا الشهر)
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthlyRevenue = members
        .where((m) {
          final start = DateTime.tryParse(m.startDate);
          return start != null && start.isAfter(monthStart);
        })
        .fold<double>(0, (sum, m) => sum + m.paidAmount);

    return MembersStats(
      totalMembers: totalMembers,
      activeMembers: activeMembers,
      expiredMembers: expiredMembers,
      monthlyRevenue: monthlyRevenue,
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
