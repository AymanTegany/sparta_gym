class ReportPaymentItem {
  final String memberName;
  final String notes;
  final double amount;
  final String date;
  final String paymentMethod;

  const ReportPaymentItem({
    required this.memberName,
    required this.notes,
    required this.amount,
    required this.date,
    this.paymentMethod = 'نقدي',
  });
}

class ReportExpenseItem {
  final String title;
  final String category;
  final double amount;
  final String date;
  final String notes;

  const ReportExpenseItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.notes,
  });
}

class ReportStats {
  final List<ReportPaymentItem> newMembers;
  final List<ReportPaymentItem> renewals;
  final List<ReportPaymentItem> singleSessions;
  final List<ReportPaymentItem> unpaidSubscriptions;
  final List<ReportExpenseItem> expenses;
  final int totalAttendance;
  final double inventorySalesRevenue;

  const ReportStats({
    required this.newMembers,
    required this.renewals,
    required this.singleSessions,
    required this.unpaidSubscriptions,
    required this.expenses,
    required this.totalAttendance,
    this.inventorySalesRevenue = 0.0,
  });

  double get newSubscriptionsRevenue => newMembers.fold(0, (sum, item) => sum + item.amount);
  double get renewalsRevenue => renewals.fold(0, (sum, item) => sum + item.amount);
  double get singleSessionsRevenue => singleSessions.fold(0, (sum, item) => sum + item.amount);
  double get unpaidAmount => unpaidSubscriptions.fold(0, (sum, item) => sum + item.amount);
  double get totalExpenses => expenses.fold(0, (sum, item) => sum + item.amount);

  double get totalRevenue => newSubscriptionsRevenue + renewalsRevenue + singleSessionsRevenue + inventorySalesRevenue;
  double get netDrawer => totalRevenue - totalExpenses;
}
