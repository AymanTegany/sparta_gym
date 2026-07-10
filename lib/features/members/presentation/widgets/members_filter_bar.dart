import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../cubit/members_state.dart';

/// شريط فلترة العملاء.
/// يعرض أزرار الفلترة: الكل | النشطين | المنتهية | قريبة الانتهاء | المديونين
class MembersFilterBar extends StatelessWidget {
  final MemberFilterType currentFilter;
  final ValueChanged<MemberFilterType> onFilterChanged;
  final Map<MemberFilterType, int> filterCounts;

  const MembersFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    this.filterCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context,
            label: 'الكل',
            filterType: MemberFilterType.all,
            icon: Icons.people_outline_rounded,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: 'النشطين',
            filterType: MemberFilterType.active,
            icon: Icons.check_circle_outline_rounded,
            activeColor: ColorPalette.activeStatus,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: 'المنتهية',
            filterType: MemberFilterType.expired,
            icon: Icons.cancel_outlined,
            activeColor: ColorPalette.expiredStatus,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: 'تنتهي قريباً',
            filterType: MemberFilterType.expiringSoon,
            icon: Icons.warning_amber_rounded,
            activeColor: ColorPalette.expiringSoonStatus,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: 'المديونين',
            filterType: MemberFilterType.inDebt,
            icon: Icons.money_off_rounded,
            activeColor: ColorPalette.debtStatus,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: 'تمرينة واحدة',
            filterType: MemberFilterType.singleSession,
            icon: Icons.bolt_rounded,
            activeColor: ColorPalette.primaryColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required MemberFilterType filterType,
    required IconData icon,
    Color? activeColor,
    required bool isDark,
  }) {
    final isSelected = currentFilter == filterType;
    final theme = Theme.of(context);
    final chipColor = activeColor ?? theme.colorScheme.primary;
    final count = filterCounts[filterType];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFilterChanged(filterType),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? chipColor.withValues(alpha: isDark ? 0.2 : 0.12)
                : (isDark
                    ? ColorPalette.cardDark
                    : Colors.white),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? chipColor.withValues(alpha: 0.5)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade300),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? chipColor
                    : (isDark
                        ? ColorPalette.textSecondaryDark
                        : ColorPalette.textSecondaryLight),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? chipColor
                      : (isDark
                          ? ColorPalette.textPrimaryDark
                          : ColorPalette.textPrimaryLight),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? chipColor.withValues(alpha: 0.2)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected
                          ? chipColor
                          : (isDark
                              ? ColorPalette.textSecondaryDark
                              : ColorPalette.textSecondaryLight),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
