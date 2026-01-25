import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
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
    // If we're loading but have no current data yet (e.g. init), show loader
    if (state.currentCalendarMonth == null && !state.isLoading) {
      // Should theoretically not happen if logic inBloc is right, but safe guard
      return const Center(child: CircularProgressIndicator());
    }

    // If strict null check fails but we are loading, we might show loader.
    // But cachedMonths logic should prevent currentCalendarMonth from being null if we had it.
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
          ),
          const SizedBox(height: 24),
          _buildTodayInfo(context, state, isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildTodayInfo(
    BuildContext context,
    CalendarLoaded state,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (state.currentCalendarMonth == null) return const SizedBox.shrink();

    // Find today's info
    final today = state.today;
    final todayData = state.currentCalendarMonth!.days.where(
      (day) =>
          day.gregorianDay == today.day &&
          day.gregorianMonth == today.month &&
          day.gregorianYear == today.year,
    );

    if (todayData.isEmpty) return const SizedBox.shrink();

    final todayInfo = todayData.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        children: [
          Text(
            l10n.tr('todayLabel'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTeal,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${todayInfo.hijriWeekdayAr} - ${todayInfo.hijriDay} ${todayInfo.hijriMonthAr} ${todayInfo.hijriYear}',
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
            '${todayInfo.gregorianWeekday}, ${todayInfo.gregorianMonthName} ${todayInfo.gregorianDay}, ${todayInfo.gregorianYear}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
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
