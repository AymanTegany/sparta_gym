import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/theme/color_palette.dart';

class RevenueChartWidget extends StatelessWidget {
  final Map<String, double> chartData;

  const RevenueChartWidget({
    super.key,
    required this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    double maxVal = 0.0;
    chartData.forEach((key, val) {
      if (val > maxVal) maxVal = val;
    });

    if (maxVal == 0.0) maxVal = 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      height: 220,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إيرادات آخر 7 أيام',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.bar_chart_rounded,
                color: ColorPalette.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.entries.map((entry) {
                final dateStr = entry.key;
                final amount = entry.value;
                final heightFactor = amount / maxVal;

                String displayDate = dateStr;
                try {
                  final parsed = DateTime.parse(dateStr);
                  displayDate = DateFormat('MM/dd').format(parsed);
                } catch (_) {}

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (amount > 0)
                        Text(
                          '${amount.toStringAsFixed(0)} ج',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else
                        const Text(
                          '—',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        height: heightFactor * 100 + 4.0,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, primary.withOpacity(0.6)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayDate,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
