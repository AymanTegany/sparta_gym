import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/membership_entity.dart';
import '../../domain/usecases/add_membership.dart';
import '../../domain/usecases/delete_membership.dart';
import '../../domain/usecases/get_all_memberships.dart';
import '../../domain/usecases/update_membership.dart';
import 'memberships_state.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// Cubit لإدارة حالات باقات الاشتراكات (Memberships Cubit)
/// ──────────────────────────────────────────────────────────────────────────────
class MembershipsCubit extends Cubit<MembershipsState> {
  final GetAllMemberships _getAllMemberships;
  final AddMembership _addMembership;
  final UpdateMembership _updateMembership;
  final DeleteMembership _deleteMembership;

  MembershipsCubit({
    required GetAllMemberships getAllMemberships,
    required AddMembership addMembership,
    required UpdateMembership updateMembership,
    required DeleteMembership deleteMembership,
  })  : _getAllMemberships = getAllMemberships,
        _addMembership = addMembership,
        _updateMembership = updateMembership,
        _deleteMembership = deleteMembership,
        super(const MembershipsInitial());

  /// تحميل الباقات
  Future<void> loadMemberships() async {
    emit(const MembershipsLoading());
    final result = await _getAllMemberships(NoParams());
    result.fold(
      (failure) => emit(MembershipsError(failure.message)),
      (memberships) => emit(MembershipsLoaded(memberships: memberships)),
    );
  }

  /// إضافة باقة جديدة
  Future<void> addMembership(Membership membership) async {
    final result = await _addMembership(membership);
    result.fold(
      (failure) => emit(MembershipsError(failure.message)),
      (_) {
        emit(const MembershipActionSuccess('تم إضافة الباقة بنجاح'));
        loadMemberships();
      },
    );
  }

  /// تحديث باقة
  Future<void> updateMembership(Membership membership) async {
    final result = await _updateMembership(membership);
    result.fold(
      (failure) => emit(MembershipsError(failure.message)),
      (_) {
        emit(const MembershipActionSuccess('تم تحديث الباقة بنجاح'));
        loadMemberships();
      },
    );
  }

  /// حذف باقة
  Future<void> deleteMembership(int id) async {
    final result = await _deleteMembership(id);
    result.fold(
      (failure) => emit(MembershipsError(failure.message)),
      (_) {
        emit(const MembershipActionSuccess('تم حذف الباقة بنجاح'));
        loadMemberships();
      },
    );
  }
}
