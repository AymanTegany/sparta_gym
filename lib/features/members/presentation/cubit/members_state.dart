import 'package:equatable/equatable.dart';
import '../../domain/entities/member_entity.dart';

/// أنواع الفلترة
enum MemberFilterType {
  all,
  active,
  expired,
  expiringSoon,
  inDebt,
}

/// إحصائيات العملاء
class MembersStats extends Equatable {
  final int totalMembers;
  final int activeMembers;
  final int expiredMembers;
  final double monthlyRevenue;

  const MembersStats({
    this.totalMembers = 0,
    this.activeMembers = 0,
    this.expiredMembers = 0,
    this.monthlyRevenue = 0,
  });

  @override
  List<Object?> get props => [totalMembers, activeMembers, expiredMembers, monthlyRevenue];
}

/// الحالة الأساسية لإدارة العملاء
abstract class MembersState extends Equatable {
  const MembersState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class MembersInitial extends MembersState {
  const MembersInitial();
}

/// حالة التحميل
class MembersLoading extends MembersState {
  const MembersLoading();
}

/// حالة تحميل البيانات بنجاح
class MembersLoaded extends MembersState {
  /// جميع العملاء (بدون فلترة)
  final List<Member> allMembers;

  /// العملاء المعروضة (بعد الفلترة والبحث)
  final List<Member> displayedMembers;

  /// نوع الفلتر الحالي
  final MemberFilterType filterType;

  /// إحصائيات العملاء
  final MembersStats stats;

  /// نص البحث الحالي
  final String searchQuery;

  const MembersLoaded({
    required this.allMembers,
    required this.displayedMembers,
    this.filterType = MemberFilterType.all,
    this.stats = const MembersStats(),
    this.searchQuery = '',
  });

  MembersLoaded copyWith({
    List<Member>? allMembers,
    List<Member>? displayedMembers,
    MemberFilterType? filterType,
    MembersStats? stats,
    String? searchQuery,
  }) {
    return MembersLoaded(
      allMembers: allMembers ?? this.allMembers,
      displayedMembers: displayedMembers ?? this.displayedMembers,
      filterType: filterType ?? this.filterType,
      stats: stats ?? this.stats,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [allMembers, displayedMembers, filterType, stats, searchQuery];
}

/// حالة الخطأ
class MembersError extends MembersState {
  final String message;

  const MembersError(this.message);

  @override
  List<Object?> get props => [message];
}

/// حالة نجاح إجراء (إضافة/تعديل/حذف)
class MemberActionSuccess extends MembersState {
  final String message;

  const MemberActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
