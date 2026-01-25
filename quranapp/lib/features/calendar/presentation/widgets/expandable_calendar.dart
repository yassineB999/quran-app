import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_event.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_state.dart';
import 'package:quranapp/features/calendar/presentation/widgets/calendar_grid.dart';
import 'package:quranapp/features/calendar/presentation/widgets/calendar_week_row.dart';

class ExpandableCalendar extends StatefulWidget {
  final CalendarLoaded state;
  final bool isDark;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const ExpandableCalendar({
    super.key,
    required this.state,
    required this.isDark,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  State<ExpandableCalendar> createState() => _ExpandableCalendarState();
}

class _ExpandableCalendarState extends State<ExpandableCalendar> {
  late PageController _pageController;
  late DateTime _focusedDate;
  // Use a base date to calculate page index.
  // Let's use current month as standard.
  // Page 1000 = initial month.
  static const int _initialPage = 1000;

  // Base anchor
  late int _baseYear;
  late int _baseMonth;

  @override
  void initState() {
    super.initState();
    _focusedDate = widget.state.today;
    _baseYear = widget.state.currentYear;
    _baseMonth = widget.state.currentMonth;
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void didUpdateWidget(ExpandableCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Sync external changes (e.g. arrows) to PageView
    final oldKey =
        '${oldWidget.state.currentYear}-${oldWidget.state.currentMonth}';
    final newKey = '${widget.state.currentYear}-${widget.state.currentMonth}';

    if (oldKey != newKey) {
      if (_baseYear == 0) return; // safety

      final targetPage = _getPageForDate(
        widget.state.currentYear,
        widget.state.currentMonth,
      );
      if (_pageController.hasClients &&
          _pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  int _getPageForDate(int year, int month) {
    final monthDiff = (year - _baseYear) * 12 + (month - _baseMonth);
    return _initialPage + monthDiff;
  }

  DateTime _getDateFromPage(int page) {
    final monthDiff = page - _initialPage;
    // Calculate new date
    // Total months from base
    final totalMonths = _baseMonth + monthDiff;

    // Normalize
    var year = _baseYear + ((totalMonths - 1) ~/ 12);
    var month = ((totalMonths - 1) % 12) + 1;

    // Handle negative months logic if needed, but the formula above usually works for positive indexes.
    // If monthDiff is negative, e.g. -1.
    // _baseMonth = 1. total = 0.
    // (0-1) ~/ 12 = -1 ~/ 12 = -1. Year = base - 1.
    // (0-1) % 12 = 11. Month = 12. Correct.

    return DateTime(year, month);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Calculate dimensions
        // Grid: 7 cols. Padding already handled by parent?
        // Parent in SliverToBoxAdapter has padding 16.
        // So 'width' here is the available width.

        final itemWidth = width / 7;
        final itemHeight = itemWidth / 0.9; // Aspect Ratio 0.9

        // Month View Height:
        // Weekday header (~30px) + 6 rows of items
        // We use 6 rows to be safe for all months (some span 6 weeks)
        final monthHeight = (itemHeight * 6) + 30 + 16; // +buffer

        // Week View Height:
        // Weekday header (~30px) + 1 row
        final weekHeight = itemHeight + 30 + 16; // +buffer

        return Column(
          children: [
            ClipRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: widget.isExpanded ? monthHeight : weekHeight,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    final date = _getDateFromPage(index);
                    context.read<CalendarBloc>().add(
                      LoadCalendarMonth(year: date.year, month: date.month),
                    );
                  },
                  itemBuilder: (context, index) {
                    final date = _getDateFromPage(index);
                    final cacheKey = '${date.year}-${date.month}';
                    final cachedMonth = widget.state.cachedMonths[cacheKey];

                    // If cached data exists, render it.
                    // Otherwise show loader (or maybe previous month's structure if we had pre-loaded logic, but simple is better)

                    if (cachedMonth != null) {
                      if (widget.isExpanded) {
                        return OverflowBox(
                          minHeight: 0,
                          maxHeight: double.infinity,
                          alignment: Alignment.topCenter,
                          child: CalendarGrid(
                            days: cachedMonth.days,
                            isDark: widget.isDark,
                          ),
                        );
                      } else {
                        // For week row, we must ensure we show the CORRECT week relative to scroll/focus?
                        // Currently we just show the week containing "focusedDate".
                        // BUT, if we swipe the PageView (months), the "focusedDate" might stay old?
                        // In `CalendarWeekRow`, we use `focusedDate` to find the week.
                        // If we swipe to next Month, `focusedDate` (which is `state.today` initally) might be in previous month.
                        // Then `_getWeekDays` might fail or return empty if day not found.

                        // Fix: If `date` (page month) != `focusedDate.month`, default to first week of that month?
                        // Or maintain a "Selected Date" in the state?
                        // For now: Default to first day of the month if focusedDate is not in this month.

                        DateTime targetDate = _focusedDate;
                        if (targetDate.month != date.month ||
                            targetDate.year != date.year) {
                          targetDate = DateTime(date.year, date.month, 1);
                        }

                        return OverflowBox(
                          minHeight: 0,
                          maxHeight: double.infinity,
                          alignment: Alignment.topCenter,
                          child: CalendarWeekRow(
                            days: cachedMonth.days,
                            today: widget.state.today,
                            focusedDate: targetDate,
                            isDark: widget.isDark,
                          ),
                        );
                      }
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ),
            GestureDetector(
              onTap: () => widget.onExpansionChanged(!widget.isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Icon(
                  widget.isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.primaryTeal.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
