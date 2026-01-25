import 'package:equatable/equatable.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

/// Load calendar for a specific month.
class LoadCalendarMonth extends CalendarEvent {
  final int year;
  final int month;
  final bool refresh;

  const LoadCalendarMonth({
    required this.year,
    required this.month,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [year, month, refresh];
}

/// Navigate to previous month.
class PreviousMonth extends CalendarEvent {
  const PreviousMonth();
}

/// Navigate to next month.
class NextMonth extends CalendarEvent {
  const NextMonth();
}

/// Go to today's month.
class GoToToday extends CalendarEvent {
  const GoToToday();
}
