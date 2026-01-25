import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';

/// Data model for HijriCalendarDay with JSON parsing.
class HijriCalendarDayModel extends HijriCalendarDay {
  const HijriCalendarDayModel({
    required super.gregorianDate,
    required super.gregorianDay,
    required super.gregorianWeekday,
    required super.gregorianMonth,
    required super.gregorianMonthName,
    required super.gregorianYear,
    required super.hijriDay,
    required super.hijriWeekdayEn,
    required super.hijriWeekdayAr,
    required super.hijriMonth,
    required super.hijriMonthEn,
    required super.hijriMonthAr,
    required super.hijriYear,
  });

  /// Creates a model from API JSON response.
  /// Expected format from aladhan.com API:
  /// ```json
  /// {
  ///   "gregorian": { "date": "01-01-2026", "day": "1", "weekday": {"en": "Thursday"}, "month": {"number": 1, "en": "January"}, "year": "2026" },
  ///   "hijri": { "day": "11", "weekday": {"en": "Al-Khamis", "ar": "الخميس"}, "month": {"number": 6, "en": "Jumada al-Thani", "ar": "جمادى الآخرة"}, "year": "1447" }
  /// }
  /// ```
  factory HijriCalendarDayModel.fromJson(Map<String, dynamic> json) {
    final gregorian = json['gregorian'] as Map<String, dynamic>? ?? {};
    final hijri = json['hijri'] as Map<String, dynamic>? ?? {};
    final gregorianWeekday =
        gregorian['weekday'] as Map<String, dynamic>? ?? {};
    final gregorianMonthData =
        gregorian['month'] as Map<String, dynamic>? ?? {};
    final hijriWeekday = hijri['weekday'] as Map<String, dynamic>? ?? {};
    final hijriMonthData = hijri['month'] as Map<String, dynamic>? ?? {};

    return HijriCalendarDayModel(
      gregorianDate: (gregorian['date'] ?? '').toString(),
      gregorianDay: int.tryParse(gregorian['day']?.toString() ?? '') ?? 0,
      gregorianWeekday: (gregorianWeekday['en'] ?? '').toString(),
      gregorianMonth:
          int.tryParse(gregorianMonthData['number']?.toString() ?? '') ?? 0,
      gregorianMonthName: (gregorianMonthData['en'] ?? '').toString(),
      gregorianYear: int.tryParse(gregorian['year']?.toString() ?? '') ?? 0,
      hijriDay: int.tryParse(hijri['day']?.toString() ?? '') ?? 0,
      hijriWeekdayEn: (hijriWeekday['en'] ?? '').toString(),
      hijriWeekdayAr: (hijriWeekday['ar'] ?? '').toString(),
      hijriMonth: int.tryParse(hijriMonthData['number']?.toString() ?? '') ?? 0,
      hijriMonthEn: (hijriMonthData['en'] ?? '').toString(),
      hijriMonthAr: (hijriMonthData['ar'] ?? '').toString(),
      hijriYear: int.tryParse(hijri['year']?.toString() ?? '') ?? 0,
    );
  }
}

/// Data model for HijriCalendarMonth with JSON parsing.
class HijriCalendarMonthModel extends HijriCalendarMonth {
  const HijriCalendarMonthModel({
    required super.gregorianYear,
    required super.gregorianMonth,
    required super.days,
    super.cached,
  });

  /// Creates a model from API JSON response.
  factory HijriCalendarMonthModel.fromJson(Map<String, dynamic> json) {
    final year = json['year'] as int? ?? 0;
    final month = json['month'] as int? ?? 0;
    final cached = json['cached'] as bool? ?? false;

    // Parse data - API wraps in "data" object with nested "data" array
    final dataWrapper = json['data'] as Map<String, dynamic>? ?? {};
    final daysList = dataWrapper['data'] as List<dynamic>? ?? [];

    final days = daysList
        .map(
          (dayJson) =>
              HijriCalendarDayModel.fromJson(dayJson as Map<String, dynamic>),
        )
        .toList();

    return HijriCalendarMonthModel(
      gregorianYear: year,
      gregorianMonth: month,
      days: days,
      cached: cached,
    );
  }
}
