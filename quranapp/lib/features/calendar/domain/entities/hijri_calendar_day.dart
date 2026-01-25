import 'package:equatable/equatable.dart';

/// Represents a single day in the Hijri calendar with both
/// Gregorian and Hijri date information.
class HijriCalendarDay extends Equatable {
  final String gregorianDate;
  final int gregorianDay;
  final String gregorianWeekday;
  final int gregorianMonth;
  final String gregorianMonthName;
  final int gregorianYear;

  final int hijriDay;
  final String hijriWeekdayEn;
  final String hijriWeekdayAr;
  final int hijriMonth;
  final String hijriMonthEn;
  final String hijriMonthAr;
  final int hijriYear;

  const HijriCalendarDay({
    required this.gregorianDate,
    required this.gregorianDay,
    required this.gregorianWeekday,
    required this.gregorianMonth,
    required this.gregorianMonthName,
    required this.gregorianYear,
    required this.hijriDay,
    required this.hijriWeekdayEn,
    required this.hijriWeekdayAr,
    required this.hijriMonth,
    required this.hijriMonthEn,
    required this.hijriMonthAr,
    required this.hijriYear,
  });

  @override
  List<Object?> get props => [
    gregorianDate,
    gregorianDay,
    gregorianWeekday,
    gregorianMonth,
    gregorianMonthName,
    gregorianYear,
    hijriDay,
    hijriWeekdayEn,
    hijriWeekdayAr,
    hijriMonth,
    hijriMonthEn,
    hijriMonthAr,
    hijriYear,
  ];
}

/// Represents a month of Hijri calendar data.
class HijriCalendarMonth extends Equatable {
  final int gregorianYear;
  final int gregorianMonth;
  final List<HijriCalendarDay> days;
  final bool cached;

  const HijriCalendarMonth({
    required this.gregorianYear,
    required this.gregorianMonth,
    required this.days,
    this.cached = false,
  });

  /// Get the Hijri month name from the first day
  String get hijriMonthName => days.isNotEmpty ? days.first.hijriMonthEn : '';
  String get hijriMonthNameAr => days.isNotEmpty ? days.first.hijriMonthAr : '';
  int get hijriYear => days.isNotEmpty ? days.first.hijriYear : 0;

  @override
  List<Object?> get props => [gregorianYear, gregorianMonth, days, cached];
}
