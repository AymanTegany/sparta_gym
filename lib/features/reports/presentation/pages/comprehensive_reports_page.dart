import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  // الفترة الافتراضية: Business Date
  ReportPeriod _period = ReportPeriod.businessDate;
  late DateTime _startDate;
  late DateTime _endDate;
  DateTimeRange? _customRange;

  // تاريخ Business Date المحدد
  late DateTime _businessDate;
  
  // أوقات بداية ونهاية يوم العمل (قابلة للتعديل)
  TimeOfDay _businessStartTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _businessEndTime = const TimeOfDay(hour: 3, minute: 0);

  @override
  void initState() {
    super.initState();
    _setInitialDates();
    _loadBusinessTimes();
  }

  void _setInitialDates() {
    final now = DateTime.now();
    
    // مبدئياً نفترض أن يوم العمل يبدأ 6 صباحاً (حتى يتم تحميل الوقت المحفوظ)
    if (now.hour < 6) {
      _businessDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    } else {
      _businessDate = DateTime(now.year, now.month, now.day);
    }
    
    _updateDatesFromShift();
  }

  Future<void> _loadBusinessTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final startHour = prefs.getInt('business_start_hour') ?? 6;
    final startMinute = prefs.getInt('business_start_minute') ?? 0;
    final endHour = prefs.getInt('business_end_hour') ?? 3;
    final endMinute = prefs.getInt('business_end_minute') ?? 0;

    setState(() {
      _businessStartTime = TimeOfDay(hour: startHour, minute: startMinute);
      _businessEndTime = TimeOfDay(hour: endHour, minute: endMinute);
      
      // إعادة حساب تاريخ الـ businessDate إذا لزم الأمر بناءً على وقت البداية المحفوظ
      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = _businessStartTime.hour * 60 + _businessStartTime.minute;
      
      if (nowMinutes < startMinutes) {
        _businessDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      } else {
        _businessDate = DateTime(now.year, now.month, now.day);
      }
      
      _updateDatesFromShift();
    });

    // يتم تحميل البيانات بعد أن نكون قد حسبنا التواريخ والأوقات بشكل صحيح
    _loadData();
  }

  Future<void> _saveBusinessTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('business_start_hour', _businessStartTime.hour);
    await prefs.setInt('business_start_minute', _businessStartTime.minute);
    await prefs.setInt('business_end_hour', _businessEndTime.hour);
    await prefs.setInt('business_end_minute', _businessEndTime.minute);
  }

  /// يحسب startDate و endDate من الـ Business Date والأوقات المحفوظة
  void _updateDatesFromShift() {
    _startDate = DateTime(
      _businessDate.year,
      _businessDate.month,
      _businessDate.day,
      _businessStartTime.hour,
      _businessStartTime.minute,
    );
    
    // إذا كان وقت النهاية أقل من وقت البداية (مثلاً 3 الفجر)، فهو في اليوم التالي
    final endMinutes = _businessEndTime.hour * 60 + _businessEndTime.minute;
    final startMinutes = _businessStartTime.hour * 60 + _businessStartTime.minute;
    final nextDay = endMinutes <= startMinutes;
    
    final targetDate = nextDay ? _businessDate.add(const Duration(days: 1)) : _businessDate;
    
    _endDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      _businessEndTime.hour,
      _businessEndTime.minute,
      59,
    );
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

    if (period == ReportPeriod.businessDate) {
      setState(() {
        _period = period;
        _updateDatesFromShift();
      });
      _loadData();
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
      case ReportPeriod.businessDate:
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

  void _onBusinessDateChanged(DateTime date) {
    setState(() {
      _businessDate = date;
      _updateDatesFromShift();
    });

    _loadData();
  }

  void _onBusinessStartTimeChanged(TimeOfDay time) {
    setState(() {
      _businessStartTime = time;
      _updateDatesFromShift();
    });
    _saveBusinessTimes();
    _loadData();
  }

  void _onBusinessEndTimeChanged(TimeOfDay time) {
    setState(() {
      _businessEndTime = time;
      _updateDatesFromShift();
    });
    _saveBusinessTimes();
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
                businessDate: _businessDate,
                onBusinessDateChanged: _onBusinessDateChanged,
                businessStartTime: _businessStartTime,
                businessEndTime: _businessEndTime,
                onBusinessStartTimeChanged: _onBusinessStartTimeChanged,
                onBusinessEndTimeChanged: _onBusinessEndTimeChanged,
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
                                          title: 'مبيعات المخزون',
                                          amount: stats.currentPosSalesRevenue,
                                          previousAmount: stats.previousPosSalesRevenue,
                                          icon: Icons.shopping_cart_rounded,
                                          color: Colors.orange,
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
                                        title: 'مبيعات المخزون',
                                        amount: stats.currentPosSalesRevenue,
                                        previousAmount: stats.previousPosSalesRevenue,
                                        icon: Icons.shopping_cart_rounded,
                                        color: Colors.orange,
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
