import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
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
  final Failure failure;
  final int year;
  final int month;

  const CalendarError({
    required this.failure,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [failure, year, month];
}
