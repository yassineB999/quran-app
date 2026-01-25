import 'package:flutter/material.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';
import 'package:quranapp/features/calendar/presentation/widgets/calendar_day_cell.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class CalendarGrid extends StatelessWidget {
  final List<HijriCalendarDay> days;
  final bool isDark;

  const CalendarGrid({super.key, required this.days, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // If days empty, maybe show empty or loader?
    // We handle that in parent PageView builder
    if (days.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    // Weekday headers
    final weekdays = [
      l10n.tr('sundayShort'),
      l10n.tr('mondayShort'),
      l10n.tr('tuesdayShort'),
      l10n.tr('wednesdayShort'),
      l10n.tr('thursdayShort'),
      l10n.tr('fridayShort'),
      l10n.tr('saturdayShort'),
    ];

    return Column(
      children: [
        // Weekday Headers
        Row(
          children: weekdays.map((day) {
            final isFriday = day == l10n.tr('fridayShort');
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isFriday
                        ? AppTheme.primaryTeal
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Days Grid
        _buildGrid(context),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    final firstDayWeekday = _getWeekdayIndex(days.first.gregorianWeekday);
    final gridItems = <Widget>[];

    // Empty cells
    for (int i = 0; i < firstDayWeekday; i++) {
      gridItems.add(const SizedBox.shrink());
    }

    // Day cells
    final now = DateTime.now();
    for (var day in days) {
      final isToday =
          day.gregorianDay == now.day &&
          day.gregorianMonth == now.month &&
          day.gregorianYear == now.year;

      gridItems.add(
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: CalendarDayCell(day: day, isToday: isToday, isDark: isDark),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      children: gridItems,
    );
  }

  int _getWeekdayIndex(String weekday) {
    switch (weekday.toLowerCase()) {
      case 'sunday':
        return 0;
      case 'monday':
        return 1;
      case 'tuesday':
        return 2;
      case 'wednesday':
        return 3;
      case 'thursday':
        return 4;
      case 'friday':
        return 5;
      case 'saturday':
        return 6;
      default:
        return 0;
    }
  }
}
