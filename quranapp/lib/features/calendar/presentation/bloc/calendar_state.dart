import 'package:equatable/equatable.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

class CalendarLoading extends CalendarState {
  final int year;
  final int month;

  const CalendarLoading({required this.year, required this.month});

  @override
  List<Object?> get props => [year, month];
}

class CalendarLoaded extends CalendarState {
  final Map<String, HijriCalendarMonth> cachedMonths;
  final int currentYear;
  final int currentMonth;
  final DateTime today;
  final bool isLoading;

  const CalendarLoaded({
    required this.cachedMonths,
    required this.currentYear,
    required this.currentMonth,
    required this.today,
    this.isLoading = false,
  });

  HijriCalendarMonth? get currentCalendarMonth {
    final key = '$currentYear-$currentMonth';
    return cachedMonths[key];
  }

  @override
  List<Object?> get props => [
    cachedMonths,
    currentYear,
    currentMonth,
    today,
    isLoading,
  ];
}

class CalendarError extends CalendarState {
  final String message;
  final int year;
  final int month;
  // Keep previous cache even on error to prevent total UI fail if possible,
  // but for simplicity we might just start fresh or hold last success.
  // Actually, we should probably just emit Loaded with error message snackbar
  // if we want to keep the UI up. But standard BLoC pattern separates Error state.
  // Let's keep it simple: Error state replaces UI.
  // Or better: CalendarLoaded can carry an error.

  const CalendarError({
    required this.message,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [message, year, month];
}
