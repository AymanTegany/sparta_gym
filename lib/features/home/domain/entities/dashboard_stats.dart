import 'package:equatable/equatable.dart';
import '../../../../features/members/domain/entities/member_entity.dart';
import '../../../../features/payments/domain/entities/payment_entity.dart';

class DashboardStats extends Equatable {
  final int totalMembers;
  final int activeMembers;
  final int expiredMembers;
  final double monthlyRevenue;
  final List<Member> expiringSoonMembers;
  final List<Payment> latestPayments;
  final int todayAttendance;
  final int currentlyInside;
  final Map<String, double> revenueChartData; // YYYY-MM-DD -> Amount
  final int expiredAlertsCount;
  final int expiringThreeDaysCount;

  const DashboardStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.expiredMembers,
    required this.monthlyRevenue,
    required this.expiringSoonMembers,
    required this.latestPayments,
    required this.todayAttendance,
    required this.currentlyInside,
    required this.revenueChartData,
    required this.expiredAlertsCount,
    required this.expiringThreeDaysCount,
  });

  @override
  List<Object?> get props => [
        totalMembers,
        activeMembers,
        expiredMembers,
        monthlyRevenue,
        expiringSoonMembers,
        latestPayments,
        todayAttendance,
        currentlyInside,
        revenueChartData,
        expiredAlertsCount,
        expiringThreeDaysCount,
      ];
}
