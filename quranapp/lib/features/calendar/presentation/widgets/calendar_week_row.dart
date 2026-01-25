import 'package:flutter/material.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';
import 'package:quranapp/features/calendar/presentation/widgets/calendar_day_cell.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class CalendarWeekRow extends StatelessWidget {
  final List<HijriCalendarDay> days;
  final DateTime today;
  final bool isDark;
  final DateTime focusedDate;

  const CalendarWeekRow({
    super.key,
    required this.days,
    required this.today,
    required this.isDark,
    required this.focusedDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (days.isEmpty) return const SizedBox.shrink();

    // Find the week containing the focusedDate
    final weekDays = _getWeekDays(days, focusedDate);

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
        // Headers
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

        // Week Row
        Row(
          children: weekDays.map((day) {
            if (day == null) return const Expanded(child: SizedBox.shrink());

            final isToday =
                day.gregorianDay == today.day &&
                day.gregorianMonth == today.month &&
                day.gregorianYear == today.year;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: CalendarDayCell(
                  day: day,
                  isToday: isToday,
                  isDark: isDark,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<HijriCalendarDay?> _getWeekDays(
    List<HijriCalendarDay> days,
    DateTime date,
  ) {
    // 1. Find the day object for the focusedDate
    final dayObj = days.cast<HijriCalendarDay>().firstWhere(
      (d) => d.gregorianDay == date.day && d.gregorianMonth == date.month,
      orElse: () => days.first, // Fallback
    );

    // 2. Identify its weekday index (Sunday=0, Saturday=6)
    final weekdayIndex = _getWeekdayIndex(dayObj.gregorianWeekday);

    // 3. Find the start of the week (Sunday)
    // We are looking for the slice of `days` that corresponds to this week.
    // However, `days` list might be missing padding for the first week of the month.
    // A robust way:
    // Construct a list of 7 items.
    // The `dayObj` should be at `weekdayIndex`.

    final week = List<HijriCalendarDay?>.filled(7, null);

    // Fill backwards
    for (int i = weekdayIndex; i >= 0; i--) {
      final targetDay = date.day - (weekdayIndex - i);
      if (targetDay < 1) continue; // Previous month

      try {
        final d = days.cast<HijriCalendarDay>().firstWhere(
          (element) => element.gregorianDay == targetDay,
        );
        week[i] = d;
      } catch (_) {}
    }

    // Fill forwards
    for (int i = weekdayIndex + 1; i < 7; i++) {
      final targetDay = date.day + (i - weekdayIndex);
      // Logic is simplified; strictly speaking we should check month boundaries properly
      // but assuming we are within the loaded month for now.
      try {
        final d = days.cast<HijriCalendarDay>().firstWhere(
          (element) => element.gregorianDay == targetDay,
        );
        week[i] = d;
      } catch (_) {}
    }

    return week;
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
