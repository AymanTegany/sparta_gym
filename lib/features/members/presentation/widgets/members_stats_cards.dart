import 'package:flutter/material.dart';
import '../../../../core/theme/color_palette.dart';
import '../cubit/members_state.dart';

/// بطاقات الإحصائيات أعلى صفحة إدارة العملاء.
/// تعرض: إجمالي العملاء، العملاء النشطون، الاشتراكات المنتهية، الإيرادات الشهرية.
class MembersStatsCards extends StatelessWidget {
  final MembersStats stats;

  const MembersStatsCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        _buildStatCard(
          context,
          title: 'إجمالي العملاء',
          value: '${stats.totalMembers}',
          icon: Icons.people_rounded,
          color: theme.colorScheme.primary,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          context,
          title: 'العملاء النشطون',
          value: '${stats.activeMembers}',
          icon: Icons.check_circle_rounded,
          color: ColorPalette.activeStatus,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          context,
          title: 'الاشتراكات المنتهية',
          value: '${stats.expiredMembers}',
          icon: Icons.cancel_rounded,
          color: ColorPalette.expiredStatus,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          context,
          title: 'الإيرادات الشهرية',
          value: '${stats.monthlyRevenue.toStringAsFixed(0)} ج.م',
          icon: Icons.monetization_on_rounded,
          color: ColorPalette.infoColor,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: _AnimatedStatCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
        isDark: isDark,
      ),
    );
  }
}

class _AnimatedStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _AnimatedStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: widget.isDark
              ? ColorPalette.cardDark
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.4)
                : (widget.isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // أيقونة في دائرة
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: _isHovered ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            // النصوص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: widget.isDark
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? ColorPalette.textPrimaryDark
                          : ColorPalette.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
