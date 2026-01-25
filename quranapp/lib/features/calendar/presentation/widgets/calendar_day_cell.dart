import 'package:flutter/material.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';

class CalendarDayCell extends StatelessWidget {
  final HijriCalendarDay day;
  final bool isToday;
  final bool isDark;

  const CalendarDayCell({
    super.key,
    required this.day,
    this.isToday = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isFriday = day.gregorianWeekday.toLowerCase() == 'friday';

    // Base colors
    final bgColor = isToday
        ? AppTheme.primaryTeal
        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white);

    final hijriColor = isToday
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    final gregorianColor = isToday
        ? Colors.white.withValues(alpha: 0.8)
        : (isDark ? Colors.white38 : Colors.black38);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: isFriday && !isToday
            ? Border.all(
                color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                width: 1,
              )
            : Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
              ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.hijriDay}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: hijriColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.gregorianDay}',
            style: TextStyle(
              fontSize: 11,
              color: gregorianColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
