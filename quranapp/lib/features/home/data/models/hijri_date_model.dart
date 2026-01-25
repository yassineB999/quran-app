import 'package:quranapp/features/home/domain/entities/hijri_date.dart';

class HijriDateModel extends HijriDate {
  const HijriDateModel({
    required super.day,
    required super.month,
    required super.year,
    required super.weekdayEn,
    required super.weekdayAr,
  });

  factory HijriDateModel.fromMap(Map<String, dynamic> map) {
    final hijri = map['hijri'] as Map<String, dynamic>? ?? {};
    final gregorian = map['gregorian'] as Map<String, dynamic>? ?? {};

    final hijriWeekday = hijri['weekday'] as Map<String, dynamic>? ?? {};
    final gregorianWeekday =
        gregorian['weekday'] as Map<String, dynamic>? ?? {};

    final monthData = hijri['month'] as Map<String, dynamic>? ?? {};

    // Use Gregorian weekday for English to avoid transliterated Arabic (e.g. "Al-Ahad" vs "Sunday")
    final weekdayEn = (gregorianWeekday['en'] ?? hijriWeekday['en'] ?? '')
        .toString();

    return HijriDateModel(
      day: (hijri['day'] ?? '').toString(),
      month: (monthData['en'] ?? '').toString(),
      year: (hijri['year'] ?? '').toString(),
      weekdayEn: weekdayEn,
      weekdayAr: (hijriWeekday['ar'] ?? '').toString(),
    );
  }

  factory HijriDateModel.fromParts({
    required String day,
    required String month,
    required String year,
    String weekdayEn = '',
    String weekdayAr = '',
  }) {
    return HijriDateModel(
      day: day,
      month: month,
      year: year,
      weekdayEn: weekdayEn,
      weekdayAr: weekdayAr,
    );
  }
}
