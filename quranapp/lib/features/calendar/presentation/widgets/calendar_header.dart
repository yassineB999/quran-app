import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_event.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class CalendarHeader extends StatelessWidget {
  final HijriCalendarMonth calendarMonth;
  final bool isDark;

  const CalendarHeader({
    super.key,
    required this.calendarMonth,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthNames = [
      l10n.tr('january'),
      l10n.tr('february'),
      l10n.tr('march'),
      l10n.tr('april'),
      l10n.tr('may'),
      l10n.tr('june'),
      l10n.tr('july'),
      l10n.tr('august'),
      l10n.tr('september'),
      l10n.tr('october'),
      l10n.tr('november'),
      l10n.tr('december'),
    ];

    final monthName = monthNames[calendarMonth.gregorianMonth - 1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () =>
                context.read<CalendarBloc>().add(const PreviousMonth()),
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppTheme.primaryTeal,
            tooltip: l10n.tr('previousMonth'),
          ),
          Column(
            children: [
              Text(
                monthName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${calendarMonth.gregorianYear}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () =>
                context.read<CalendarBloc>().add(const NextMonth()),
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppTheme.primaryTeal,
            tooltip: l10n.tr('nextMonth'),
          ),
        ],
      ),
    );
  }
}
