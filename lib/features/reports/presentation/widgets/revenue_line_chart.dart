import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' as intl;
import '../../domain/entities/report_stats.dart';
import '../../domain/entities/comprehensive_report_data.dart';

class ChartPoint {
  final String label;
  final double value;
  final double xValue;
  final bool showLabel;

  ChartPoint({
    required this.label,
    required this.value,
    required this.xValue,
    this.showLabel = true,
  });
}

class RevenueLineChart extends StatelessWidget {
  final List<ReportPaymentItem> payments;
  final List<ReportPosSaleItem> posSales;
  final DateTime startDate;
  final DateTime endDate;

  const RevenueLineChart({
    super.key,
    required this.payments,
    required this.posSales,
    required this.startDate,
    required this.endDate,
  });

  List<ChartPoint> _generateChartPoints() {
    final difference = endDate.difference(startDate);

    if (difference.inDays <= 1) {
      // تجميع بالساعة (اليوم)
      Map<int, double> hourlyRevenue = {};
      for (var p in payments) {
        final dt = DateTime.tryParse(p.date);
        if (dt != null) {
          hourlyRevenue[dt.hour] = (hourlyRevenue[dt.hour] ?? 0.0) + p.amount;
        }
      }
      for (var s in posSales) {
        final dt = DateTime.tryParse(s.date);
        if (dt != null) {
          hourlyRevenue[dt.hour] = (hourlyRevenue[dt.hour] ?? 0.0) + s.finalAmount;
        }
      }

      List<ChartPoint> points = [];
      for (int h = 0; h < 24; h += 2) {
        double val = 0.0;
        val += hourlyRevenue[h] ?? 0.0;
        val += hourlyRevenue[h + 1] ?? 0.0;
        // تنسيق الساعة 12h
        final hourLabel = h == 0
            ? '12ص'
            : h == 12
                ? '12م'
                : h > 12
                    ? '${h - 12}م'
                    : '${h}ص';
        points.add(ChartPoint(label: hourLabel, value: val, xValue: h.toDouble()));
      }
      return points;
    } else if (difference.inDays <= 8) {
      // تجميع باليوم (الأسبوع)
      List<ChartPoint> points = [];
      for (int i = 0; i <= difference.inDays; i++) {
        final dayDate = startDate.add(Duration(days: i));
        final dayStr = intl.DateFormat('yyyy-MM-dd').format(dayDate);
        final label = intl.DateFormat('EEEE', 'ar').format(dayDate); // اسم اليوم كامل

        double val = 0.0;
        for (var p in payments) {
          if (p.date.startsWith(dayStr)) val += p.amount;
        }
        for (var s in posSales) {
          if (s.date.startsWith(dayStr)) val += s.finalAmount;
        }
        points.add(ChartPoint(label: label, value: val, xValue: i.toDouble()));
      }
      return points;
    } else if (difference.inDays <= 32) {
      // تجميع باليوم (الشهر)
      List<ChartPoint> points = [];
      for (int i = 0; i <= difference.inDays; i++) {
        final dayDate = startDate.add(Duration(days: i));
        final dayStr = intl.DateFormat('yyyy-MM-dd').format(dayDate);
        final label = intl.DateFormat('d/M').format(dayDate);

        double val = 0.0;
        for (var p in payments) {
          if (p.date.startsWith(dayStr)) val += p.amount;
        }
        for (var s in posSales) {
          if (s.date.startsWith(dayStr)) val += s.finalAmount;
        }
        points.add(ChartPoint(
          label: label,
          value: val,
          xValue: i.toDouble(),
          showLabel: i % 4 == 0 || i == difference.inDays, // عرض بعض التسميات فقط لعدم الازدحام
        ));
      }
      return points;
    } else {
      // تجميع بالشهر (السنة)
      List<ChartPoint> points = [];
      DateTime tempDate = DateTime(startDate.year, startDate.month);
      int index = 0;
      while (tempDate.isBefore(endDate) || (tempDate.year == endDate.year && tempDate.month == endDate.month)) {
        final monthStr = intl.DateFormat('yyyy-MM').format(tempDate);
        final label = intl.DateFormat('MMM', 'ar').format(tempDate); // اسم الشهر باللغة العربية

        double val = 0.0;
        for (var p in payments) {
          if (p.date.startsWith(monthStr)) val += p.amount;
        }
        for (var s in posSales) {
          if (s.date.startsWith(monthStr)) val += s.finalAmount;
        }
        points.add(ChartPoint(label: label, value: val, xValue: index.toDouble()));

        tempDate = DateTime(tempDate.year, tempDate.month + 1);
        index++;
      }
      return points;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final points = _generateChartPoints();
    final totalRevenue = points.fold(0.0, (sum, p) => sum + p.value);

    // التحقق من وجود بيانات كافية (إذا كانت كل القيم صفرًا)
    if (totalRevenue == 0) {
      return Container(
        height: 300,
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
                Icons.trending_down_rounded,
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

    // إيجاد القيمة العظمى لتحديد تدريج المحور الرأسي
    double maxValue = points.fold(0.0, (max, p) => p.value > max ? p.value : max);
    if (maxValue == 0) maxValue = 1000;
    // زيادة بسيطة للأعلى للمظهر الجمالي
    final roundedMax = (maxValue * 1.15).ceilToDouble();

    return Container(
      height: 380,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'مخطط حركة الإيرادات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'إجمالي الفترة: ${intl.NumberFormat('#,##0', 'ar').format(totalRevenue)} ج',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr, // fl_chart يفضل ltr لتوجيه المحاور بشكل سليم
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final intIndex = value.toInt();
                          if (intIndex < 0 || intIndex >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final point = points[intIndex];
                          if (!point.showLabel) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              point.label,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          // اختصار الأرقام الكبيرة
                          String text = '';
                          if (value >= 1000000) {
                            text = '${(value / 1000000).toStringAsFixed(1)}M';
                          } else if (value >= 1000) {
                            text = '${(value / 1000).toStringAsFixed(0)}K';
                          } else {
                            text = value.toStringAsFixed(0);
                          }
                          return Text(
                            text,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1.5),
                      left: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1.5),
                    ),
                  ),
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: roundedMax,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      tooltipRoundedRadius: 8,
                      tooltipBorder: BorderSide(color: Colors.purple.withOpacity(0.3), width: 1),
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final point = points[barSpot.x.toInt()];
                          return LineTooltipItem(
                            '${point.label}\n',
                            const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: '${intl.NumberFormat('#,##0', 'ar').format(point.value)} ج',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: points.map((p) => FlSpot(p.xValue, p.value)).toList(),
                      isCurved: true,
                      preventCurveOverShooting: true,
                      gradient: const LinearGradient(
                        colors: [
                          Colors.purpleAccent,
                          Colors.deepPurple,
                        ],
                      ),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: points.length <= 15, // إظهار النقاط فقط إذا كانت البيانات قليلة
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: Colors.deepPurple,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.35),
                            Colors.purple.withOpacity(0.01),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
