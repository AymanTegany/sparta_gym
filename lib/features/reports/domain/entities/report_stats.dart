class ReportStats {
  final double newSubscriptionsRevenue;
  final double renewalsRevenue;
  final double inventorySalesRevenue;
  final int totalAttendance;

  const ReportStats({
    required this.newSubscriptionsRevenue,
    required this.renewalsRevenue,
    required this.inventorySalesRevenue,
    required this.totalAttendance,
  });

  double get totalRevenue =>
      newSubscriptionsRevenue + renewalsRevenue + inventorySalesRevenue;
}
