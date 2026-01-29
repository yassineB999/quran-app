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
    // Event Flags
    final isRamadan = day.isRamadan;
    final isEid = day.isEidAlFitr || day.isEidAlAdha;
    final hasHolidays = day.holidays.isNotEmpty;
    final isFriday = day.gregorianWeekday.toLowerCase() == 'friday';

    // Determining Background Color
    Color bgColor;
    if (isToday) {
      bgColor = AppTheme.primaryTeal;
    } else if (isEid) {
      bgColor = const Color(0xFFFFB300).withValues(alpha: 0.2); // Amber tint
    } else if (isRamadan) {
      bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.1); // Green tint
    } else {
      bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    }

    // Determining Text Colors
    final hijriColor = isToday
        ? Colors.white
        : (isEid
              ? const Color(0xFFFFB300)
              : (isDark ? Colors.white : Colors.black87));

    final gregorianColor = isToday
        ? Colors.white.withValues(alpha: 0.8)
        : (isDark ? Colors.white38 : Colors.black38);

    // Border Logic
    BoxBorder? border;
    if (!isToday) {
      if (isEid) {
        border = Border.all(color: const Color(0xFFFFB300), width: 1.5);
      } else if (isRamadan) {
        border = Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
          width: 1,
        );
      } else if (isFriday) {
        border = Border.all(
          color: AppTheme.primaryTeal.withValues(alpha: 0.3),
          width: 1,
        );
      } else {
        border = Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: border,
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : (isEid
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.hijriDay}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hijriColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '${day.gregorianDay}',
                style: TextStyle(
                  fontSize: 10,
                  color: gregorianColor,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
              if (hasHolidays && !isToday && !isEid) ...[
                const SizedBox(height: 2),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white70 : Colors.black54,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          if (hasHolidays && (isToday || isEid))
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : const Color(0xFFFFB300),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
