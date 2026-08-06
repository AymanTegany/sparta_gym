import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/theme/color_palette.dart';

enum ReportPeriod { businessDate, today, week, month, year, custom }

class ReportFilterBar extends StatelessWidget {
  final ReportPeriod selectedPeriod;
  final Function(ReportPeriod) onPeriodSelected;
  final DateTimeRange? customRange;
  final Function(DateTimeRange) onCustomRangeSelected;

  // تاريخ يوم العمل (Business Date)
  final DateTime? businessDate;
  final Function(DateTime)? onBusinessDateChanged;

  // أوقات يوم العمل
  final TimeOfDay? businessStartTime;
  final TimeOfDay? businessEndTime;
  final Function(TimeOfDay)? onBusinessStartTimeChanged;
  final Function(TimeOfDay)? onBusinessEndTimeChanged;

  const ReportFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
    required this.customRange,
    required this.onCustomRangeSelected,
    this.businessDate,
    this.onBusinessDateChanged,
    this.businessStartTime,
    this.businessEndTime,
    this.onBusinessStartTimeChanged,
    this.onBusinessEndTimeChanged,
  });

  String _getPeriodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.businessDate:
        return 'Business Date';
      case ReportPeriod.today:
        return 'اليوم';
      case ReportPeriod.week:
        return 'الأسبوع';
      case ReportPeriod.month:
        return 'الشهر';
      case ReportPeriod.year:
        return 'السنة';
      case ReportPeriod.custom:
        return 'نطاق تاريخ';
    }
  }

  /// يحسب بداية يوم العمل: الساعة 6 صباحاً
  static DateTime shiftStart(DateTime date) {
    return DateTime(date.year, date.month, date.day, 6, 0, 0);
  }

  /// يحسب نهاية يوم العمل: الساعة 3 فجراً في اليوم التالي
  static DateTime shiftEnd(DateTime date) {
    final nextDay = date.add(const Duration(days: 1));
    return DateTime(nextDay.year, nextDay.month, nextDay.day, 3, 0, 0);
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final initialRange = customRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialRange,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorPalette.primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Cairo'),
              titleMedium: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (pickedRange != null) {
      onCustomRangeSelected(pickedRange);
    }
  }

  Future<void> _pickDate(BuildContext context, DateTime initial, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorPalette.primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Cairo'),
              titleMedium: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('yyyy/MM/dd', 'ar');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ReportPeriod.values.map((period) {
              final isSelected = selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ChoiceChip(
                  label: Text(
                    _getPeriodLabel(period),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? Colors.grey.shade300
                              : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: ColorPalette.primaryColor,
                  backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  elevation: isSelected ? 3 : 0,
                  shadowColor: ColorPalette.primaryColor.withOpacity(0.4),
                  onSelected: (selected) {
                    if (selected) {
                      onPeriodSelected(period);
                      if (period == ReportPeriod.custom) {
                        _selectCustomRange(context);
                      }
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Business Date (يوم العمل)
        if (selectedPeriod == ReportPeriod.businessDate && businessDate != null) ...[
          const SizedBox(height: 14),
          _buildShiftPanel(context, isDark, dateFormat),
        ],

        // نطاق تاريخ مخصص
        if (selectedPeriod == ReportPeriod.custom && customRange != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ColorPalette.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorPalette.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: ColorPalette.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'الفترة المحددة: من ${dateFormat.format(customRange!.start)} إلى ${dateFormat.format(customRange!.end)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _selectCustomRange(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'تعديل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  Widget _buildShiftPanel(BuildContext context, bool isDark, intl.DateFormat dateFormat) {
    final dayNameFormat = intl.DateFormat('EEEE', 'ar');
    final nextDay = businessDate!.add(const Duration(days: 1));
    
    final startTimeString = businessStartTime != null ? _formatTime(businessStartTime!) : '6:00 ص';
    final endTimeString = businessEndTime != null ? _formatTime(businessEndTime!) : '3:00 ص';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withOpacity(0.5)
            : ColorPalette.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorPalette.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // أيقونة + عنوان
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.work_history_rounded,
                color: ColorPalette.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Business Date',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.primaryColor,
                ),
              ),
            ],
          ),

          // اليوم الأول (الجزء الأول)
          _buildDatePartChip(
            context: context,
            isDark: isDark,
            label: 'اليوم الأول',
            date: businessDate!,
            timeText: 'من $startTimeString  ←  إلى 11:59 م',
            dateFormat: dateFormat,
            dayNameFormat: dayNameFormat,
            color: Colors.blue,
            onDateTap: () => _pickDate(context, businessDate!, (picked) {
              onBusinessDateChanged?.call(picked);
            }),
            onTimeTap: () async {
              if (businessStartTime == null) return;
              final picked = await showTimePicker(
                context: context,
                initialTime: businessStartTime!,
              );
              if (picked != null) onBusinessStartTimeChanged?.call(picked);
            },
          ),

          // علامة +
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: ColorPalette.primaryColor,
              size: 16,
            ),
          ),

          // اليوم الثاني (الجزء الثاني)
          _buildDatePartChip(
            context: context,
            isDark: isDark,
            label: 'اليوم الثاني',
            date: nextDay,
            timeText: 'من 12:00 ص  ←  إلى $endTimeString',
            dateFormat: dateFormat,
            dayNameFormat: dayNameFormat,
            color: Colors.deepOrange,
            onDateTap: () => _pickDate(context, businessDate!, (picked) {
              onBusinessDateChanged?.call(picked);
            }),
            onTimeTap: () async {
              if (businessEndTime == null) return;
              final picked = await showTimePicker(
                context: context,
                initialTime: businessEndTime!,
              );
              if (picked != null) onBusinessEndTimeChanged?.call(picked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDatePartChip({
    required BuildContext context,
    required bool isDark,
    required String label,
    required DateTime date,
    required String timeText,
    required intl.DateFormat dateFormat,
    required intl.DateFormat dayNameFormat,
    required Color color,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // سطر التاريخ
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDateTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, color: color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$label: ${dayNameFormat.format(date)} ${dateFormat.format(date)}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? color.withOpacity(0.9) : color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_rounded, color: color.withOpacity(0.4), size: 13),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // سطر وقت البداية والنهاية
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTimeTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        size: 13),
                    const SizedBox(width: 4),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_rounded, color: color.withOpacity(0.4), size: 13),
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
