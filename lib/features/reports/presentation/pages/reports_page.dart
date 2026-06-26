import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/common/widgets/sidebar_layout.dart';
import '../../../../core/theme/color_palette.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    context.read<ReportsCubit>().loadReports(_startDate, _endDate);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorPalette.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReports();
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, ThemeData theme) {
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
      title: 'التقارير اليومية',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _selectDateRange(context),
          icon: const Icon(Icons.date_range_rounded),
          label: Text(
            '${DateFormat('yyyy-MM-dd').format(_startDate)}  إلى  ${DateFormat('yyyy-MM-dd').format(_endDate)}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadReports,
          tooltip: 'تحديث البيانات',
        ),
      ],
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state is ReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReportsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text('حدث خطأ:', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(state.message, style: const TextStyle(color: Colors.grey)),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملخص الإيرادات',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        context,
                        'إيرادات الاشتراكات الجديدة',
                        '${NumberFormat('#,##0', 'ar').format(stats.newSubscriptionsRevenue)} ج',
                        Icons.person_add_alt_1_rounded,
                        ColorPalette.primaryColor,
                        theme,
                      ),
                      _buildStatCard(
                        context,
                        'إيرادات التجديدات',
                        '${NumberFormat('#,##0', 'ar').format(stats.renewalsRevenue)} ج',
                        Icons.autorenew_rounded,
                        ColorPalette.successColor,
                        theme,
                      ),
                      _buildStatCard(
                        context,
                        'مبيعات المخزن',
                        '${NumberFormat('#,##0', 'ar').format(stats.inventorySalesRevenue)} ج',
                        Icons.storefront_rounded,
                        Colors.orange,
                        theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'إحصائيات أخرى',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStatCard(
                        context,
                        'إجمالي إيرادات الفترة',
                        '${NumberFormat('#,##0', 'ar').format(stats.totalRevenue)} ج',
                        Icons.monetization_on_rounded,
                        ColorPalette.warningColor,
                        theme,
                      ),
                      _buildStatCard(
                        context,
                        'عدد الحضور',
                        '${stats.totalAttendance}',
                        Icons.people_alt_rounded,
                        Colors.purple,
                        theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // إحصائيات للمدير مختصرة ورسمية جدا
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_rounded, color: Colors.blueGrey, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'تقرير الإدارة المختصر',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Text(
                          'ملخص أداء الفترة من ${DateFormat('yyyy-MM-dd').format(_startDate)} إلى ${DateFormat('yyyy-MM-dd').format(_endDate)}:',
                          style: const TextStyle(height: 1.5, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Text('• إجمالي التدفقات النقدية للإيرادات: ${NumberFormat('#,##0', 'ar').format(stats.totalRevenue)} جنيه.', style: const TextStyle(fontSize: 15, height: 1.5)),
                        Text('• إيرادات الاشتراكات (جديد + تجديد): ${NumberFormat('#,##0', 'ar').format(stats.newSubscriptionsRevenue + stats.renewalsRevenue)} جنيه.', style: const TextStyle(fontSize: 15, height: 1.5)),
                        Text('• مبيعات نقاط البيع (المخزن): ${NumberFormat('#,##0', 'ar').format(stats.inventorySalesRevenue)} جنيه.', style: const TextStyle(fontSize: 15, height: 1.5)),
                        Text('• إجمالي الزيارات المسجلة (الحضور): ${stats.totalAttendance} زيارة.', style: const TextStyle(fontSize: 15, height: 1.5)),
                        const SizedBox(height: 24),
                        const Text(
                          'يُرجى مراجعة الإيرادات أعلاه واعتمادها في الدفاتر المالية.',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
