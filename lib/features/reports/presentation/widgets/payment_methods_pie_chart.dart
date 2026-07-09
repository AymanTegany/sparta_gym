import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' as intl;
import '../../domain/entities/report_stats.dart';
import '../../domain/entities/comprehensive_report_data.dart';
import '../../../../core/theme/color_palette.dart';

class PaymentMethodsPieChart extends StatefulWidget {
  final List<ReportPaymentItem> payments;
  final List<ReportPosSaleItem> posSales;

  const PaymentMethodsPieChart({
    super.key,
    required this.payments,
    required this.posSales,
  });

  @override
  State<PaymentMethodsPieChart> createState() => _PaymentMethodsPieChartState();
}

class _PaymentMethodsPieChartState extends State<PaymentMethodsPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double cash = 0.0;
    double visa = 0.0;
    double wallet = 0.0;

    // تجميع طرق الدفع للمدفوعات
    for (var p in widget.payments) {
      final method = p.paymentMethod.trim();
      if (method == 'نقدي' || method == 'كاش' || method == 'نقداً' || method == '') {
        cash += p.amount;
      } else if (method == 'بطاقة' || method.toLowerCase().contains('فيزا') || method.toLowerCase().contains('visa') || method.toLowerCase().contains('card')) {
        visa += p.amount;
      } else {
        wallet += p.amount;
      }
    }

    // تجميع طرق الدفع للمبيعات (نقطة البيع)
    for (var s in widget.posSales) {
      final method = s.paymentMethod.trim();
      if (method == 'نقدي' || method == 'كاش' || method == 'نقداً' || method == '') {
        cash += s.finalAmount;
      } else if (method == 'بطاقة' || method.toLowerCase().contains('فيزا') || method.toLowerCase().contains('visa') || method.toLowerCase().contains('card')) {
        visa += s.finalAmount;
      } else {
        wallet += s.finalAmount;
      }
    }

    final total = cash + visa + wallet;

    if (total == 0) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد بيانات كافية لهذه الفترة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // تجهيز أقسام الرسم الدائري
    List<PieChartSectionData> _getSections() {
      final List<Map<String, dynamic>> items = [
        {
          'value': cash,
          'color': ColorPalette.primaryColor,
          'title': 'كاش',
        },
        {
          'value': visa,
          'color': Colors.blue.shade600,
          'title': 'فيزا',
        },
        {
          'value': wallet,
          'color': Colors.purple.shade600,
          'title': 'محفظة',
        },
      ];

      return List.generate(items.length, (i) {
        final isTouched = i == touchedIndex;
        final double radius = isTouched ? 45.0 : 35.0;
        final double value = items[i]['value'] as double;
        final double percentage = (value / total) * 100;

        return PieChartSectionData(
          color: items[i]['color'] as Color,
          value: value,
          title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: radius,
          titleStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      });
    }

    final numberFormat = intl.NumberFormat('#,##0', 'ar');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'توزيع الإيرادات حسب طريقة الدفع',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: _getSections(),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'الإجمالي',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${numberFormat.format(total)} ج',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      color: ColorPalette.primaryColor,
                      title: 'كاش / نقدي',
                      amount: cash,
                      percentage: (cash / total) * 100,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      color: Colors.blue.shade600,
                      title: 'بطاقة / فيزا',
                      amount: visa,
                      percentage: (visa / total) * 100,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      color: Colors.purple.shade600,
                      title: 'محفظة إلكترونية',
                      amount: wallet,
                      percentage: (wallet / total) * 100,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String title,
    required double amount,
    required double percentage,
  }) {
    final numberFormat = intl.NumberFormat('#,##0', 'ar');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${numberFormat.format(amount)} ج (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
