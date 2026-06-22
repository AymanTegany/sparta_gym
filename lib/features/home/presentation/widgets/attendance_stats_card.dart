import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

class AttendanceStatsCard extends StatelessWidget {
  final int totalToday;
  final int currentInside;

  const AttendanceStatsCard({
    super.key,
    required this.totalToday,
    required this.currentInside,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حضور اليوم',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons.people_outline,
                  color: ColorPalette.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$totalToday',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'إجمالي حضور اليوم',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 60, color: theme.dividerColor),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$currentInside',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.successColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'الموجودون الآن بالجيم',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
