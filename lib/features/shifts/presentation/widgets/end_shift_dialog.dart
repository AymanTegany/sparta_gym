import 'package:flutter/material.dart';

import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/shift_entity.dart';

/// مربع حوار تأكيد إنهاء الشفت الحالي.
class EndShiftDialog extends StatelessWidget {
  final Shift currentShift;
  final VoidCallback onConfirm;

  const EndShiftDialog({
    super.key,
    required this.currentShift,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── أيقونة التحذير ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorPalette.warningColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: ColorPalette.warningColor,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),

                // ── العنوان ──
                Text(
                  'إنهاء الشفت',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? ColorPalette.textPrimaryDark
                        : ColorPalette.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'هل أنت متأكد من إنهاء الشفت؟',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? ColorPalette.textSecondaryDark
                        : ColorPalette.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // ── معلومات الشفت ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorPalette.cardDark
                        : ColorPalette.backgroundLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      // اسم الموظف
                      _buildInfoRow(
                        icon: Icons.person_rounded,
                        label: 'الموظف',
                        value: currentShift.employeeName,
                        color: theme.colorScheme.primary,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      // مدة الشفت
                      _buildInfoRow(
                        icon: Icons.timer_rounded,
                        label: 'مدة الشفت',
                        value: currentShift.durationText,
                        color: ColorPalette.infoColor,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── ملاحظة ──
                Text(
                  'سيتم حساب التقرير النهائي بعد إنهاء الشفت.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? ColorPalette.textSecondaryDark
                        : ColorPalette.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // ── الأزرار ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? ColorPalette.textPrimaryDark
                                : ColorPalette.textPrimaryLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                        icon: const Icon(Icons.stop_rounded, size: 20),
                        label: const Text(
                          'إنهاء الشفت',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? ColorPalette.textPrimaryDark
                    : ColorPalette.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
