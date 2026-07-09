import 'report_stats.dart';

class ReportPosSaleItem {
  final double finalAmount;
  final String date;
  final String paymentMethod;

  const ReportPosSaleItem({
    required this.finalAmount,
    required this.date,
    required this.paymentMethod,
  });
}

class OverdueMemberItem {
  final String memberId;
  final String fullName;
  final String phoneNumber;
  final String membershipType;
  final double remainingAmount;
  final String startDate;
  final String endDate;

  const OverdueMemberItem({
    required this.memberId,
    required this.fullName,
    required this.phoneNumber,
    required this.membershipType,
    required this.remainingAmount,
    required this.startDate,
    required this.endDate,
  });
}

class ComprehensiveReportData {
  final List<ReportPaymentItem> currentPayments;
  final List<ReportExpenseItem> currentExpenses;
  final List<ReportPosSaleItem> currentPosSales;
  
  final List<ReportPaymentItem> previousPayments;
  final List<ReportExpenseItem> previousExpenses;
  final List<ReportPosSaleItem> previousPosSales;

  final List<OverdueMemberItem> overdueMembers;

  const ComprehensiveReportData({
    required this.currentPayments,
    required this.currentExpenses,
    required this.currentPosSales,
    required this.previousPayments,
    required this.previousExpenses,
    required this.previousPosSales,
    required this.overdueMembers,
  });

  double get currentPaymentsRevenue => currentPayments.fold(0.0, (sum, item) => sum + item.amount);
  double get currentPosSalesRevenue => currentPosSales.fold(0.0, (sum, item) => sum + item.finalAmount);
  double get currentTotalRevenue => currentPaymentsRevenue + currentPosSalesRevenue;
  double get currentTotalExpenses => currentExpenses.fold(0.0, (sum, item) => sum + item.amount);
  double get currentNetProfit => currentTotalRevenue - currentTotalExpenses;

  double get previousPaymentsRevenue => previousPayments.fold(0.0, (sum, item) => sum + item.amount);
  double get previousPosSalesRevenue => previousPosSales.fold(0.0, (sum, item) => sum + item.finalAmount);
  double get previousTotalRevenue => previousPaymentsRevenue + previousPosSalesRevenue;
  double get previousTotalExpenses => previousExpenses.fold(0.0, (sum, item) => sum + item.amount);
  double get previousNetProfit => previousTotalRevenue - previousTotalExpenses;

  double get totalOverdueAmount => overdueMembers.fold(0.0, (sum, item) => sum + item.remainingAmount);
}
