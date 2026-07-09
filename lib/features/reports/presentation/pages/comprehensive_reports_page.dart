import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/common/widgets/sidebar_layout.dart';
import '../../../../core/theme/color_palette.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/revenue_line_chart.dart';
import '../widgets/payment_methods_pie_chart.dart';
import '../widgets/overdue_members_widget.dart';

class ComprehensiveReportsPage extends StatefulWidget {
  const ComprehensiveReportsPage({super.key});

  @override
  State<ComprehensiveReportsPage> createState() => _ComprehensiveReportsPageState();
}

class _ComprehensiveReportsPageState extends State<ComprehensiveReportsPage> {
  ReportPeriod _period = ReportPeriod.week;
  late DateTime _startDate;
  late DateTime _endDate;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _setInitialDates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _setInitialDates() {
    final now = DateTime.now();
    // افتراضياً: آخر 7 أيام شاملة اليوم
    _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  void _loadData() {
    context.read<ReportsCubit>().loadComprehensiveReports(_startDate, _endDate);
  }

  void _onPeriodChanged(ReportPeriod period) {
    if (period == ReportPeriod.custom) {
      setState(() {
        _period = period;
      });
      return;
    }

    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (period) {
      case ReportPeriod.today:
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        break;
      case ReportPeriod.week:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        break;
      case ReportPeriod.month:
        start = DateTime(now.year, now.month, 1, 0, 0, 0);
        break;
      case ReportPeriod.year:
        start = DateTime(now.year, 1, 1, 0, 0, 0);
        break;
      case ReportPeriod.custom:
        return;
    }

    setState(() {
      _period = period;
      _startDate = start;
      _endDate = end;
    });

    _loadData();
  }

  void _onCustomRangeChanged(DateTimeRange range) {
    setState(() {
      _customRange = range;
      _startDate = DateTime(range.start.year, range.start.month, range.start.day, 0, 0, 0);
      _endDate = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    });

    _loadData();
  }

  double _calculatePercentageChange(double current, double previous) {
    if (previous == 0) {
      return current > 0 ? 100.0 : 0.0;
    }
    return ((current - previous) / previous) * 100;
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required double previousAmount,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final numberFormat = intl.NumberFormat('#,##0', 'ar');
    final percentage = _calculatePercentageChange(amount, previousAmount);
    final isIncrease = percentage >= 0;
    final badgeColor = isIncrease ? Colors.green : Colors.red;
    final badgeIcon = isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final sign = isIncrease ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${numberFormat.format(amount)} ج',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(badgeIcon, color: badgeColor, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '$sign${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'عن الفترة السابقة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SidebarLayout(
      activePage: 'comprehensive_reports',
      title: 'التقارير الشاملة',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadData,
          tooltip: 'تحديث البيانات',
        ),
      ],
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. شريط الفلاتر
              ReportFilterBar(
                selectedPeriod: _period,
                onPeriodSelected: _onPeriodChanged,
                customRange: _customRange,
                onCustomRangeSelected: _onCustomRangeChanged,
              ),
              const SizedBox(height: 24),

              // 2. محتوى التقارير المالية
              Expanded(
                child: BlocBuilder<ReportsCubit, ReportsState>(
                  builder: (context, state) {
                    if (state is ReportsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ReportsError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: ColorPalette.errorColor,
                              size: 60,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'حدث خطأ أثناء تحميل البيانات',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is ComprehensiveReportsLoaded) {
                      final stats = state.stats;

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 900;

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // كروت الملخص المالي
                                if (isDesktop)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildSummaryCard(
                                          title: 'إجمالي الإيرادات',
                                          amount: stats.currentTotalRevenue,
                                          previousAmount: stats.previousTotalRevenue,
                                          icon: Icons.trending_up_rounded,
                                          color: Colors.purple,
                                          isDark: isDark,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildSummaryCard(
                                          title: 'إجمالي المصروفات',
                                          amount: stats.currentTotalExpenses,
                                          previousAmount: stats.previousTotalExpenses,
                                          icon: Icons.money_off_rounded,
                                          color: ColorPalette.errorColor,
                                          isDark: isDark,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildSummaryCard(
                                          title: 'صافي الأرباح',
                                          amount: stats.currentNetProfit,
                                          previousAmount: stats.previousNetProfit,
                                          icon: Icons.account_balance_wallet_rounded,
                                          color: Colors.teal,
                                          isDark: isDark,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      _buildSummaryCard(
                                        title: 'إجمالي الإيرادات',
                                        amount: stats.currentTotalRevenue,
                                        previousAmount: stats.previousTotalRevenue,
                                        icon: Icons.trending_up_rounded,
                                        color: Colors.purple,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildSummaryCard(
                                        title: 'إجمالي المصروفات',
                                        amount: stats.currentTotalExpenses,
                                        previousAmount: stats.previousTotalExpenses,
                                        icon: Icons.money_off_rounded,
                                        color: ColorPalette.errorColor,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildSummaryCard(
                                        title: 'صافي الأرباح',
                                        amount: stats.currentNetProfit,
                                        previousAmount: stats.previousNetProfit,
                                        icon: Icons.account_balance_wallet_rounded,
                                        color: Colors.teal,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 24),

                                // الرسوم البيانية
                                if (isDesktop)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 6,
                                        child: RevenueLineChart(
                                          payments: stats.currentPayments,
                                          posSales: stats.currentPosSales,
                                          startDate: state.startDate,
                                          endDate: state.endDate,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 4,
                                        child: PaymentMethodsPieChart(
                                          payments: stats.currentPayments,
                                          posSales: stats.currentPosSales,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      RevenueLineChart(
                                        payments: stats.currentPayments,
                                        posSales: stats.currentPosSales,
                                        startDate: state.startDate,
                                        endDate: state.endDate,
                                      ),
                                      const SizedBox(height: 24),
                                      PaymentMethodsPieChart(
                                        payments: stats.currentPayments,
                                        posSales: stats.currentPosSales,
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 24),

                                // جدول المستحقات
                                OverdueMembersWidget(
                                  overdueMembers: stats.overdueMembers,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          );
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
