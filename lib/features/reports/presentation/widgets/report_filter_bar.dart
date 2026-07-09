import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/theme/color_palette.dart';

enum ReportPeriod { today, week, month, year, custom }

class ReportFilterBar extends StatelessWidget {
  final ReportPeriod selectedPeriod;
  final Function(ReportPeriod) onPeriodSelected;
  final DateTimeRange? customRange;
  final Function(DateTimeRange) onCustomRangeSelected;

  const ReportFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
    required this.customRange,
    required this.onCustomRangeSelected,
  });

  String _getPeriodLabel(ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return 'اليوم';
      case ReportPeriod.week:
        return 'الأسبوع';
      case ReportPeriod.month:
        return 'الشهر';
      case ReportPeriod.year:
        return 'السنة';
      case ReportPeriod.custom:
        return 'فترة مخصصة';
    }
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = intl.DateFormat('yyyy/MM/dd', 'ar');

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
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: ColorPalette.primaryColor,
                  backgroundColor: Colors.grey.shade200,
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
}
