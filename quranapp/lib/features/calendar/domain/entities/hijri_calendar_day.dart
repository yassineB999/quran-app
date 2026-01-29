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
  final List<String> holidays;

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
    this.holidays = const [],
  });

  bool get isRamadan => hijriMonth == 9;

  bool get isEidAlFitr => hijriMonth == 10 && (hijriDay >= 1 && hijriDay <= 3);

  bool get isEidAlAdha =>
      hijriMonth == 12 && (hijriDay >= 10 && hijriDay <= 13);

  bool get isHolyDay => isRamadan || isEidAlFitr || isEidAlAdha;

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
    holidays,
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
