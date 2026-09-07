import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/member_entity.dart';

/// جدول بيانات العملاء مع Pagination.
/// يعرض: رقم العضوية، الاسم، الهاتف، نوع الاشتراك، تاريخ البداية، الانتهاء، الحالة،
/// المدفوع، المتبقي، الأيام المتبقية، الإجراءات.
class MembersDataTable extends StatefulWidget {
  final List<Member> members;
  final Function(Member) onEdit;
  final Function(Member) onDelete;
  final Function(Member) onViewDetails;
  final Function(Member) onRenew;
  final Function(Member) onAddPayment;
  final Function(Member) onPrintCard;
  final Function(Member) onWhatsAppAlert;
  final Function(Member) onWelcomeMessage;
  final Function(Member) onRefundAndDelete;
  final Function(Member) onEditMemberId;

  const MembersDataTable({
    super.key,
    required this.members,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
    required this.onRenew,
    required this.onAddPayment,
    required this.onPrintCard,
    required this.onWhatsAppAlert,
    required this.onWelcomeMessage,
    required this.onRefundAndDelete,
    required this.onEditMemberId,
  });

  @override
  State<MembersDataTable> createState() => _MembersDataTableState();
}

class _MembersDataTableState extends State<MembersDataTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  late List<Member> _sortedMembers;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sortedMembers = List.from(widget.members);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MembersDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.members != widget.members) {
      _sortedMembers = List.from(widget.members);
    }
  }

  void _sort<T>(
    Comparable<T> Function(Member m) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortedMembers.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  // ثوابت أعمدة الجدول
  static const List<_ColumnDef> _columns = [
    _ColumnDef('رقم العضوية', 120),
    _ColumnDef('الاسم', 180),
    _ColumnDef('رقم الهاتف', 130),
    _ColumnDef('نوع الاشتراك', 140),
    _ColumnDef('تاريخ البداية', 120),
    _ColumnDef('تاريخ الانتهاء', 120),
    _ColumnDef('الحالة', 120),
    _ColumnDef('المدفوع', 100),
    _ColumnDef('المتبقي', 100),
    _ColumnDef('أيام متبقية', 100),
    _ColumnDef('الإجراءات', 60),
  ];

  static double get _totalWidth =>
      _columns.fold<double>(0, (sum, c) => sum + c.width) + 32; // +32 for margins

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_sortedMembers.isEmpty) {
      return _buildEmptyState(context, isDark);
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? ColorPalette.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade200,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                notificationPredicate: (notification) => notification.depth == 0,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _totalWidth,
                    child: Column(
                      children: [
                        // ── صف العناوين (ثابت) ──
                        _buildHeaderRow(theme, isDark),
                        // ── صفوف البيانات (كسول - يبني فقط المرئي) ──
                        Expanded(
                          child: Scrollbar(
                            controller: _verticalScrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _verticalScrollController,
                              itemCount: _sortedMembers.length,
                              itemExtent: 54, // ارتفاع ثابت لكل صف لتسريع التمرير
                              itemBuilder: (context, index) {
                                return _buildDataRow(
                                  context, _sortedMembers[index], index, theme, isDark);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// بناء صف العناوين
  Widget _buildHeaderRow(ThemeData theme, bool isDark) {
    final sortIcons = List<Widget?>.filled(_columns.length, null);
    if (_sortColumnIndex < _columns.length) {
      sortIcons[_sortColumnIndex] = Icon(
        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 14,
        color: Colors.white70,
      );
    }

    // الأعمدة القابلة للفرز: 0 (رقم العضوية), 1 (الاسم), 4 (تاريخ البداية), 5 (الانتهاء), 7 (المدفوع), 8 (المتبقي), 9 (أيام متبقية)
    final sortableColumns = {0, 1, 4, 5, 7, 8, 9};
    final sortFunctions = <int, Comparable Function(Member)>{
      0: (m) => m.memberId,
      1: (m) => m.fullName,
      4: (m) => m.startDate,
      5: (m) => m.endDate,
      7: (m) => m.paidAmount,
      8: (m) => m.remainingAmount,
      9: (m) => m.remainingDays,
    };

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? ColorPalette.tableHeaderDark
            : ColorPalette.tableHeaderLight,
      ),
      child: Row(
        children: List.generate(_columns.length, (i) {
          final col = _columns[i];
          final isSortable = sortableColumns.contains(i);
          return SizedBox(
            width: col.width,
            child: InkWell(
              onTap: isSortable
                  ? () {
                      final ascending = _sortColumnIndex == i ? !_sortAscending : true;
                      _sort(sortFunctions[i]!, i, ascending);
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        col.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sortIcons[i] != null) sortIcons[i]!,
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// بناء صف بيانات واحد (يُبنى فقط عند الظهور في الشاشة)
  Widget _buildDataRow(
    BuildContext context,
    Member member,
    int index,
    ThemeData theme,
    bool isDark,
  ) {
    final isEvenRow = index.isEven;
    final bgColor = isEvenRow
        ? (isDark ? ColorPalette.tableRowEvenDark : ColorPalette.tableRowEvenLight)
        : (isDark ? ColorPalette.tableRowOddDark : ColorPalette.tableRowOddLight);

    return Material(
      color: bgColor,
      child: InkWell(
        hoverColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        onTap: () => widget.onViewDetails(member),
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              // رقم العضوية
              SizedBox(
                width: _columns[0].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _MemberIdCell(
                    memberId: member.memberId,
                    theme: theme,
                    onEditTap: () => widget.onEditMemberId(member),
                  ),
                ),
              ),
              // الاسم
              SizedBox(
                width: _columns[1].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          member.fullName.isNotEmpty ? member.fullName[0] : '?',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          member.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // رقم الهاتف
              SizedBox(
                width: _columns[2].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(member.phoneNumber ?? '-', overflow: TextOverflow.ellipsis),
                ),
              ),
              // نوع الاشتراك
              SizedBox(
                width: _columns[3].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      member.membershipType,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              // تاريخ البداية
              SizedBox(
                width: _columns[4].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(_formatDate(member.startDate)),
                ),
              ),
              // تاريخ الانتهاء
              SizedBox(
                width: _columns[5].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(_formatDate(member.endDate)),
                ),
              ),
              // الحالة
              SizedBox(
                width: _columns[6].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildStatusBadge(member),
                ),
              ),
              // المدفوع
              SizedBox(
                width: _columns[7].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${member.paidAmount.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      color: isDark
                          ? ColorPalette.textPrimaryDark
                          : ColorPalette.textPrimaryLight,
                    ),
                  ),
                ),
              ),
              // المتبقي
              SizedBox(
                width: _columns[8].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${member.remainingAmount.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      color: member.hasDebt
                          ? ColorPalette.debtStatus
                          : ColorPalette.activeStatus,
                      fontWeight: member.hasDebt ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              // أيام متبقية
              SizedBox(
                width: _columns[9].width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${member.remainingDays} يوم',
                    style: TextStyle(
                      color: member.remainingDays == 0
                          ? ColorPalette.expiredStatus
                          : member.remainingDays <= 7
                          ? ColorPalette.expiringSoonStatus
                          : (isDark
                                ? ColorPalette.textPrimaryDark
                                : ColorPalette.textPrimaryLight),
                      fontWeight: member.remainingDays <= 7
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              // الإجراءات
              SizedBox(
                width: _columns[10].width,
                child: _buildActionsMenu(context, member, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء شارة الحالة
  Widget _buildStatusBadge(Member member) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    if (!member.isActive) {
      bgColor = ColorPalette.expiredStatus.withValues(alpha: 0.12);
      textColor = ColorPalette.expiredStatus;
      text = 'منتهي';
      icon = Icons.cancel_rounded;
    } else if (member.isExpiringSoon) {
      bgColor = ColorPalette.expiringSoonStatus.withValues(alpha: 0.12);
      textColor = ColorPalette.expiringSoonStatus;
      text = 'ينتهي قريباً';
      icon = Icons.warning_rounded;
    } else {
      bgColor = ColorPalette.activeStatus.withValues(alpha: 0.12);
      textColor = ColorPalette.activeStatus;
      text = 'نشط';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// قائمة الإجراءات
  Widget _buildActionsMenu(BuildContext context, Member member, bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: isDark
            ? ColorPalette.textSecondaryDark
            : ColorPalette.textSecondaryLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? ColorPalette.cardDark : Colors.white,
      elevation: 8,
      onSelected: (value) {
        switch (value) {
          case 'view':
            widget.onViewDetails(member);
            break;
          case 'edit':
            widget.onEdit(member);
            break;
          case 'edit_member_id':
            widget.onEditMemberId(member);
            break;
          case 'renew':
            widget.onRenew(member);
            break;
          case 'payment':
            widget.onAddPayment(member);
            break;
          case 'print':
            widget.onPrintCard(member);
            break;
          case 'whatsapp':
            widget.onWhatsAppAlert(member);
            break;
          case 'welcome_msg':
            widget.onWelcomeMessage(member);
            break;
          case 'refund_delete':
            widget.onRefundAndDelete(member);
            break;
          case 'delete':
            widget.onDelete(member);
            break;
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem(
          'view',
          Icons.visibility_rounded,
          'عرض التفاصيل',
          isDark,
        ),
        _buildPopupItem('edit', Icons.edit_rounded, 'تعديل', isDark),
        _buildPopupItem(
          'edit_member_id',
          Icons.tag_rounded,
          'تعديل رقم العضوية',
          isDark,
        ),
        _buildPopupItem(
          'renew',
          Icons.autorenew_rounded,
          'تجديد اشتراك',
          isDark,
        ),
        _buildPopupItem('payment', Icons.payment_rounded, 'إضافة دفعة', isDark),
        _buildPopupItem('print', Icons.print_rounded, 'طباعة بطاقة', isDark),
        _buildPopupItem('whatsapp', Icons.chat_rounded, 'تنبيه واتساب', isDark),
        _buildPopupItem('welcome_msg', Icons.waving_hand_rounded, 'رسالة ترحيب', isDark),
        const PopupMenuDivider(),
        _buildPopupItem(
          'refund_delete',
          Icons.money_off_rounded,
          'ارجاع مبلغ الاشتراك وحذف العميل',
          isDark,
          isDestructive: true,
        ),
        _buildPopupItem(
          'delete',
          Icons.delete_rounded,
          'حذف',
          isDark,
          isDestructive: true,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String label,
    bool isDark, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDestructive
                ? ColorPalette.errorColor
                : (isDark
                      ? ColorPalette.textSecondaryDark
                      : ColorPalette.textSecondaryLight),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isDestructive
                  ? ColorPalette.errorColor
                  : (isDark
                        ? ColorPalette.textPrimaryDark
                        : ColorPalette.textPrimaryLight),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حالة عدم وجود بيانات
  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: isDark ? ColorPalette.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 72,
            color: isDark
                ? ColorPalette.textSecondaryDark.withValues(alpha: 0.4)
                : ColorPalette.textSecondaryLight.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'لا يوجد عملاء',
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة عميل جديد للبدء',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorPalette.textSecondaryDark.withValues(alpha: 0.7)
                  : ColorPalette.textSecondaryLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق التاريخ
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy/MM/dd').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}

/// ويدجت خلية رقم العضوية مع أيقونة تعديل عند المرور عليها
class _MemberIdCell extends StatefulWidget {
  final String memberId;
  final ThemeData theme;
  final VoidCallback onEditTap;

  const _MemberIdCell({
    required this.memberId,
    required this.theme,
    required this.onEditTap,
  });

  @override
  State<_MemberIdCell> createState() => _MemberIdCellState();
}

class _MemberIdCellState extends State<_MemberIdCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.memberId,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: widget.theme.colorScheme.primary,
            ),
          ),
          AnimatedOpacity(
            opacity: _isHovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: widget.onEditTap,
                borderRadius: BorderRadius.circular(4),
                child: Tooltip(
                  message: 'تعديل رقم العضوية',
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: widget.theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// تعريف عمود في الجدول
class _ColumnDef {
  final String label;
  final double width;

  const _ColumnDef(this.label, this.width);
}
