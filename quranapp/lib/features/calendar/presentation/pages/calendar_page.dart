import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_event.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_state.dart';
import 'package:quranapp/features/calendar/presentation/widgets/calendar_header.dart';
import 'package:quranapp/features/calendar/presentation/widgets/expandable_calendar.dart';
import 'package:quranapp/features/calendar/presentation/widgets/hijri_month_info_card.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return BlocProvider(
      create: (_) =>
          sl<CalendarBloc>()
            ..add(LoadCalendarMonth(year: now.year, month: now.month)),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  bool _isExpanded = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.7),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        title: Text(
          l10n.tr('calendar'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.7),
              child: IconButton(
                onPressed: () =>
                    context.read<CalendarBloc>().add(const GoToToday()),
                icon: Icon(Icons.today_rounded, color: AppTheme.primaryTeal),
                tooltip: l10n.tr('todayLabel'),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF0F0F1A)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE8ECF0)],
          ),
        ),
        child: SafeArea(
          child: BlocBuilder<CalendarBloc, CalendarState>(
            builder: (context, state) {
              if (state is CalendarLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CalendarError) {
                return _buildError(context, state, l10n);
              }

              if (state is CalendarLoaded) {
                // Update selected date if not set (first load)
                _selectedDate ??= state.today;

                return _buildCalendarContent(context, state, isDark, l10n);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarContent(
    BuildContext context,
    CalendarLoaded state,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (state.currentCalendarMonth == null && !state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentMonth = state.currentCalendarMonth;
    if (currentMonth == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CalendarHeader(calendarMonth: currentMonth, isDark: isDark),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isExpanded
                ? Column(
                    children: [
                      HijriMonthInfoCard(
                        calendarMonth: currentMonth,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          ExpandableCalendar(
            state: state,
            isDark: isDark,
            isExpanded: _isExpanded,
            onExpansionChanged: (val) {
              setState(() {
                _isExpanded = val;
              });
            },
            onDaySelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          const SizedBox(height: 24),
          _buildSelectedDayInfo(context, state, isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildSelectedDayInfo(
    BuildContext context,
    CalendarLoaded state,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (state.currentCalendarMonth == null || _selectedDate == null) {
      return const SizedBox.shrink();
    }

    HijriCalendarDay? dayInfo;

    HijriCalendarDay? findInMonth(HijriCalendarMonth month) {
      try {
        return month.days.firstWhere(
          (d) =>
              d.gregorianDay == _selectedDate!.day &&
              d.gregorianMonth == _selectedDate!.month &&
              d.gregorianYear == _selectedDate!.year,
        );
      } catch (e) {
        return null;
      }
    }

    if (state.currentCalendarMonth != null) {
      dayInfo = findInMonth(state.currentCalendarMonth!);
    }

    if (dayInfo == null) {
      for (final month in state.cachedMonths.values) {
        dayInfo = findInMonth(month);
        if (dayInfo != null) {
          break;
        }
      }
    }

    if (dayInfo == null) return const SizedBox.shrink();

    final events = <String>[];
    if (dayInfo.isEidAlFitr) {
      final name = l10n.tr('eidAlFitr');
      events.add(name == 'eidAlFitr' ? 'Eid al-Fitr' : name);
    }
    if (dayInfo.isEidAlAdha) {
      final name = l10n.tr('eidAlAdha');
      events.add(name == 'eidAlAdha' ? 'Eid al-Adha' : name);
    }
    if (dayInfo.isRamadan) {
      final name = l10n.tr('ramadan');
      events.add(name == 'ramadan' ? 'Ramadan' : name);
    }

    if (dayInfo.holidays.isNotEmpty) {
      for (var h in dayInfo.holidays) {
        if (!events.contains(h)) events.add(h);
      }
    }

    final isEventDay = events.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? (isEventDay
                  ? const Color(0xFF2C2C1E)
                  : Colors.white.withValues(alpha: 0.05))
            : (isEventDay
                  ? const Color(0xFFFFF9C4).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEventDay
              ? const Color(0xFFFFB300)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
          width: isEventDay ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isEventDay) ...[
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB300),
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                isEventDay ? l10n.tr('specialEvent') : l10n.tr('selectedDate'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isEventDay
                      ? const Color(0xFFFFB300)
                      : AppTheme.primaryTeal,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${dayInfo.hijriWeekdayAr} - ${dayInfo.hijriDay} ${dayInfo.hijriMonthAr} ${dayInfo.hijriYear}',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${dayInfo.gregorianWeekday}, ${dayInfo.gregorianMonthName} ${dayInfo.gregorianDay}, ${dayInfo.gregorianYear}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          if (isEventDay) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                events.join(" • "),
                style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    CalendarError state,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tr('errorOccurred'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<CalendarBloc>().add(
                  LoadCalendarMonth(
                    year: state.year,
                    month: state.month,
                    refresh: true,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
