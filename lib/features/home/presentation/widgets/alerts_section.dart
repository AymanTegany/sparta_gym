import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';

class AlertsSection extends StatelessWidget {
  final int expiredAlerts;
  final int expiringThreeDays;

  const AlertsSection({
    super.key,
    required this.expiredAlerts,
    required this.expiringThreeDays,
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
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: ColorPalette.errorColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'التنبيهات المهمة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (expiredAlerts == 0 && expiringThreeDays == 0)
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: ColorPalette.successColor,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'لا توجد تنبيهات عاجلة اليوم، كل شيء مستقر.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              )
            else
              Column(
                children: [
                  if (expiredAlerts > 0)
                    ListTile(
                      leading: const Icon(
                        Icons.error_outline_rounded,
                        color: ColorPalette.errorColor,
                      ),
                      title: Text(
                        'يوجد $expiredAlerts اشتراكات منتهية تحتاج إلى تجديد.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      dense: true,
                    ),
                  if (expiringThreeDays > 0)
                    ListTile(
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: ColorPalette.warningColor,
                      ),
                      title: Text(
                        'يوجد $expiringThreeDays اشتراكات تنتهي خلال الـ 3 أيام القادمة.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      dense: true,
                    ),
                  const ListTile(
                    leading: Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey,
                    ),
                    title: Text(
                      'المخزون: لا توجد منتجات أوشكت على النفاد.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    dense: true,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
