import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/shift_report_entity.dart';

/// صفحة تقرير نهاية الشفت — تعرض ملخص شامل لأداء الشفت.
class ShiftReportPage extends StatelessWidget {
  final ShiftReport report;
  final VoidCallback onNewShift;
  final bool isActiveShift;

  const ShiftReportPage({
    super.key,
    required this.report,
    required this.onNewShift,
    this.isActiveShift = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final numberFmt = NumberFormat('#,##0.00', 'ar');
    final countFmt = NumberFormat('#,##0', 'ar');
    final timeFmt = DateFormat('hh:mm a', 'ar');
    final dateFmt = DateFormat('EEEE، d MMMM yyyy', 'ar');

    return Scaffold(
      backgroundColor:
          isDark ? ColorPalette.backgroundDark : ColorPalette.backgroundLight,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  // ── Header ──
                  _buildHeader(theme, isDark, primary, timeFmt, dateFmt),
                  const SizedBox(height: 24),

                  // ── معلومات الشفت ──
                  _buildShiftInfoCard(theme, isDark, primary, timeFmt),
                  const SizedBox(height: 20),

                  // ── تفصيل الإيرادات ──
                  _buildSectionTitle('تفصيل الإيرادات', Icons.trending_up_rounded,
                      ColorPalette.successColor),
                  const SizedBox(height: 12),
                  _buildRevenueGrid(theme, isDark, numberFmt),
                  const SizedBox(height: 20),

                  // ── الملخص المالي ──
                  _buildSectionTitle(
                      'الملخص المالي', Icons.account_balance_wallet_rounded, primary),
                  const SizedBox(height: 12),
                  _buildFinancialSummary(theme, isDark, primary, numberFmt),
                  const SizedBox(height: 20),

                  // ── الإحصائيات ──
                  _buildSectionTitle(
                      'الإحصائيات', Icons.bar_chart_rounded, ColorPalette.infoColor),
                  const SizedBox(height: 12),
                  _buildStatsGrid(theme, isDark, countFmt),
                  const SizedBox(height: 32),

                  // ── زر بدء شفت جديد أو إغلاق ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: isActiveShift ? () => Navigator.pop(context) : onNewShift,
                      icon: Icon(isActiveShift ? Icons.close_rounded : Icons.play_arrow_rounded, size: 24),
                      label: Text(
                        isActiveShift ? 'إغلاق التقرير' : 'بدء شفت جديد',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActiveShift ? Colors.grey.shade700 : primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Header
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(ThemeData theme, bool isDark, Color primary,
      DateFormat timeFmt, DateFormat dateFmt) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.assessment_rounded, color: primary, size: 44),
        ),
        const SizedBox(height: 16),
        Text(
          isActiveShift ? 'تقرير الشفت (مباشر)' : 'تقرير نهاية الشفت',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark
                ? ColorPalette.textPrimaryDark
                : ColorPalette.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateFmt.format(report.startTime),
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? ColorPalette.textSecondaryDark
                : ColorPalette.textSecondaryLight,
          ),
        ),
        if (isActiveShift) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Text(
              'الفترة: ${report.employeeName}  •  مفتوحة منذ: ${_formatDuration(DateTime.now().difference(report.startTime))}',
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else {
      return '$minutes دقيقة';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // معلومات الشفت
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildShiftInfoCard(
      ThemeData theme, bool isDark, Color primary, DateFormat timeFmt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // الأفاتار
          CircleAvatar(
            radius: 28,
            backgroundColor: primary.withOpacity(0.15),
            child: Text(
              report.employeeName.isNotEmpty
                  ? report.employeeName.substring(0, 1)
                  : '؟',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.employeeName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark
                        ? ColorPalette.textPrimaryDark
                        : ColorPalette.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'مدة الشفت: ${report.durationText}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? ColorPalette.textSecondaryDark
                        : ColorPalette.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // أوقات البداية والنهاية
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildTimeChip(
                'البداية',
                timeFmt.format(report.startTime),
                ColorPalette.successColor,
              ),
              const SizedBox(height: 6),
              _buildTimeChip(
                'النهاية',
                timeFmt.format(report.endTime),
                ColorPalette.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String label, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $time',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // عنوان قسم
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // شبكة الإيرادات
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRevenueGrid(ThemeData theme, bool isDark, NumberFormat fmt) {
    final items = [
      _MetricData(
        icon: Icons.person_add_alt_1_rounded,
        label: 'اشتراكات جديدة',
        value: fmt.format(report.newSubscriptionsRevenue),
        color: const Color(0xFF10B981),
      ),
      _MetricData(
        icon: Icons.autorenew_rounded,
        label: 'تجديدات',
        value: fmt.format(report.renewalsRevenue),
        color: const Color(0xFF06B6D4),
      ),
      _MetricData(
        icon: Icons.payments_rounded,
        label: 'مدفوعات أخرى',
        value: fmt.format(report.otherPaymentsRevenue),
        color: const Color(0xFF8B5CF6),
      ),
      _MetricData(
        icon: Icons.shopping_bag_rounded,
        label: 'مبيعات المخزون',
        value: fmt.format(report.inventorySalesRevenue),
        color: const Color(0xFFF59E0B),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: items
          .map((item) => _buildMetricCard(theme, isDark, item))
          .toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // الملخص المالي (إجمالي الإيرادات، المصروفات، صافي الربح)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFinancialSummary(
      ThemeData theme, bool isDark, Color primary, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFinancialRow(
            label: 'إجمالي الإيرادات',
            value: fmt.format(report.totalRevenue),
            color: ColorPalette.successColor,
            icon: Icons.arrow_upward_rounded,
            isDark: isDark,
          ),
          Divider(
            color: isDark ? Colors.white12 : Colors.black12,
            height: 24,
          ),
          _buildFinancialRow(
            label: 'إجمالي المصروفات',
            value: fmt.format(report.totalExpenses),
            color: ColorPalette.errorColor,
            icon: Icons.arrow_downward_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: report.netProfit >= 0
                    ? [
                        ColorPalette.infoColor.withOpacity(0.1),
                        ColorPalette.infoColor.withOpacity(0.05),
                      ]
                    : [
                        ColorPalette.errorColor.withOpacity(0.1),
                        ColorPalette.errorColor.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: report.netProfit >= 0
                    ? ColorPalette.infoColor.withOpacity(0.3)
                    : ColorPalette.errorColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      color: report.netProfit >= 0
                          ? ColorPalette.infoColor
                          : ColorPalette.errorColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'صافي الربح',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark
                            ? ColorPalette.textPrimaryDark
                            : ColorPalette.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  fmt.format(report.netProfit),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: report.netProfit >= 0
                        ? ColorPalette.infoColor
                        : ColorPalette.errorColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialRow({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // شبكة الإحصائيات (أعداد)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsGrid(ThemeData theme, bool isDark, NumberFormat fmt) {
    final items = [
      _MetricData(
        icon: Icons.person_add_rounded,
        label: 'أعضاء جدد',
        value: fmt.format(report.newMembersCount),
        color: const Color(0xFF10B981),
      ),
      _MetricData(
        icon: Icons.autorenew_rounded,
        label: 'تجديدات',
        value: fmt.format(report.renewalsCount),
        color: const Color(0xFF06B6D4),
      ),
      _MetricData(
        icon: Icons.how_to_reg_rounded,
        label: 'حضور',
        value: fmt.format(report.totalAttendance),
        color: const Color(0xFF8B5CF6),
      ),
      _MetricData(
        icon: Icons.receipt_long_rounded,
        label: 'عمليات دفع',
        value: fmt.format(report.totalPaymentsCount),
        color: const Color(0xFFF59E0B),
      ),
      _MetricData(
        icon: Icons.shopping_cart_rounded,
        label: 'عمليات بيع',
        value: fmt.format(report.totalSalesCount),
        color: const Color(0xFFEC4899),
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items
          .map((item) => _buildMetricCard(theme, isDark, item))
          .toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // بطاقة مقياس عامة
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMetricCard(ThemeData theme, bool isDark, _MetricData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 16, color: data.color),
              ),
              const Spacer(),
              Text(
                data.value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: data.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// نموذج بيانات مقياس
// ══════════════════════════════════════════════════════════════════════════════

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
