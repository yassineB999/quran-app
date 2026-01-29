import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';

/// Abstract repository for calendar data operations.
abstract class CalendarRepository {
  /// Fetches the Hijri calendar for a specific Gregorian month/year.
  ///
  /// [year] - Gregorian year
  /// [month] - Gregorian month (1-12)
  /// [refresh] - Force refresh from API instead of cache
  Future<Either<Failure, HijriCalendarMonth>> getCalendarMonth({
    required int year,
    required int month,
    bool refresh = false,
  });

  /// Fetches the Hijri calendar for a specific Gregorian year.
  Future<Either<Failure, List<HijriCalendarMonth>>> getCalendarYear({
    required int year,
    bool refresh = false,
  });
}
