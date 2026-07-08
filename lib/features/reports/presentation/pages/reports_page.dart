import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/common/widgets/sidebar_layout.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/report_stats.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../../../../features/shifts/presentation/cubit/shifts_cubit.dart';
import '../../../../features/shifts/presentation/cubit/shifts_state.dart';
import '../../../../features/shifts/presentation/widgets/shift_management_dialog.dart';
import '../../../shifts/presentation/pages/shift_report_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    final shiftState = context.read<ShiftsCubit>().state;
    if (shiftState is ShiftsActiveShift) {
      final startTime = shiftState.shift.startTime;
      final endTime = DateTime.now();
      context.read<ReportsCubit>().loadReports(startTime, endTime);
    }
  }

  // Dialog helpers
  void _showPaymentsListDialog(
    BuildContext context,
    String title,
    List<ReportPaymentItem> items,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: items.isEmpty
              ? const Center(child: Text('لا توجد بيانات'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        item.memberName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item.notes),
                      trailing: Text(
                        '${item.amount} ج',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showExpensesListDialog(
    BuildContext context,
    List<ReportExpenseItem> expenses,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('المصروفات التفصيلية'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: expenses.isEmpty
              ? const Center(child: Text('لا توجد مصروفات'))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.money_off, color: Colors.white),
                      ),
                      title: Text(
                        exp.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${exp.category} - ${exp.date.substring(0, 10)}\n${exp.notes}',
                      ),
                      trailing: Text(
                        '${exp.amount} ج',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // List Card Builder
  Widget _buildListCard({
    required BuildContext context,
    required String title,
    required String countLabel,
    required String amountLabel,
    required List<ReportPaymentItem> items,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final totalAmount = items.fold(0.0, (sum, i) => sum + i.amount);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '$countLabel: ${items.length}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (amountLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '$amountLabel: ${NumberFormat('#,##0', 'ar').format(totalAmount)} ج',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'لا يوجد',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: items.length > 5
                        ? 5
                        : items.length, // Show max 5 items
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          item.memberName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '${item.amount} ج',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () => _showPaymentsListDialog(context, title, items),
            child: const Text('إظهار الكل'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
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

    return SidebarLayout(
      activePage: 'reports',
      title: 'التقارير',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadReports,
          tooltip: 'تحديث البيانات',
        ),
      ],
      body: BlocBuilder<ShiftsCubit, ShiftsState>(
        builder: (context, shiftState) {
          if (shiftState is! ShiftsActiveShift) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'التقارير مقفلة',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'برجاء فتح شفت لتتمكن من عرض التقارير والإحصائيات.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ShiftManagementDialog(),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('فتح شفت الآن'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final report = await context
                          .read<ShiftsCubit>()
                          .getLastClosedShiftReport();
                      if (report != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShiftReportPage(
                              report: report,
                              onNewShift: () {},
                              isActiveShift: false,
                            ),
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('لا يوجد سجل شفتات سابق لعرضه'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('سجل آخر شيفت'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return BlocBuilder<ReportsCubit, ReportsState>(
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
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text('حدث خطأ:', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadReports,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              if (state is ReportsLoaded) {
                final stats = state.stats;
                final shift = shiftState.shift;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رسالة تفاصيل الشفت
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: Colors.orange,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'هذا التقرير لـ (شفت ${shift.employeeName}) منذ الساعة ${DateFormat('hh:mm a', 'ar').format(shift.startTime)} وحتى الآن.',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'الملخص المالي وصافي الدرج',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white30, height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'إيرادات أعضاء جدد',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${NumberFormat('#,##0', 'ar').format(stats.newSubscriptionsRevenue)} ج',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'إيرادات تجديدات',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${NumberFormat('#,##0', 'ar').format(stats.renewalsRevenue)} ج',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'إيرادات حصص فردية',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${NumberFormat('#,##0', 'ar').format(stats.singleSessionsRevenue)} ج',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'مبيعات المخزون',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${NumberFormat('#,##0', 'ar').format(stats.inventorySalesRevenue)} ج',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'إجمالي آجل (على الحساب)',
                                            style: TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${NumberFormat('#,##0', 'ar').format(stats.unpaidAmount)} ج',
                                            style: const TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 120,
                                  color: Colors.white30,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'إجمالي المصروفات',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${NumberFormat('#,##0', 'ar').format(stats.totalExpenses)} ج',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'صافي الدرج',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${NumberFormat('#,##0', 'ar').format(stats.netDrawer)} ج',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 1. التفاصيل (أعضاء، تجديدات، حصص)
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5, // Adjusted for 2 columns
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildListCard(
                            context: context,
                            title: 'الأعضاء الجدد',
                            countLabel: 'العدد',
                            amountLabel: '',
                            items: stats.newMembers,
                            icon: Icons.person_add_alt_1_rounded,
                            color: ColorPalette.primaryColor,
                          ),
                          _buildListCard(
                            context: context,
                            title: 'تجديد الاشتراكات',
                            countLabel: 'العدد',
                            amountLabel: '',
                            items: stats.renewals,
                            icon: Icons.autorenew_rounded,
                            color: ColorPalette.successColor,
                          ),
                          _buildListCard(
                            context: context,
                            title: 'الحصص الفردية',
                            countLabel: 'العدد',
                            amountLabel: 'الإجمالي',
                            items: stats.singleSessions,
                            icon: Icons.fitness_center_rounded,
                            color: Colors.orange,
                          ),
                          _buildListCard(
                            context: context,
                            title: 'اشتراكات على الحساب',
                            countLabel: 'العدد',
                            amountLabel: 'المتبقي',
                            items: stats.unpaidSubscriptions,
                            icon: Icons.credit_card_off_rounded,
                            color: Colors.orange,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 2. إحصائيات عامة (المصروفات والحضور)
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 3.5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          InkWell(
                            onTap: () => _showExpensesListDialog(
                              context,
                              stats.expenses,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: _buildSimpleStatCard(
                              context,
                              'إجمالي المصروفات (اضغط للتفاصيل)',
                              '${NumberFormat('#,##0', 'ar').format(stats.totalExpenses)} ج',
                              Icons.money_off_rounded,
                              Colors.redAccent,
                            ),
                          ),
                          _buildSimpleStatCard(
                            context,
                            'إجمالي عدد الحضور',
                            '${stats.totalAttendance} زيارة',
                            Icons.qr_code_scanner_rounded,
                            Colors.purple,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
