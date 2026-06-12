import 'package:equatable/equatable.dart';
import '../../domain/entities/membership_entity.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// حالات إدارة باقات الاشتراكات (Memberships State)
/// ──────────────────────────────────────────────────────────────────────────────
abstract class MembershipsState extends Equatable {
  const MembershipsState();

  @override
  List<Object?> get props => [];
}

class MembershipsInitial extends MembershipsState {
  const MembershipsInitial();
}

class MembershipsLoading extends MembershipsState {
  const MembershipsLoading();
}

class MembershipsLoaded extends MembershipsState {
  final List<Membership> memberships;

  const MembershipsLoaded({required this.memberships});

  @override
  List<Object?> get props => [memberships];
}

class MembershipsError extends MembershipsState {
  final String message;

  const MembershipsError(this.message);

  @override
  List<Object?> get props => [message];
}

class MembershipActionSuccess extends MembershipsState {
  final String message;

  const MembershipActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
