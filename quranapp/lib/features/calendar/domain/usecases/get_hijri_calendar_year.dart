import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';
import 'package:quranapp/features/calendar/domain/repositories/calendar_repository.dart';

/// Use case to fetch Hijri calendar data for a full Gregorian year.
class GetHijriCalendarYear
    implements UseCase<List<HijriCalendarMonth>, CalendarYearParams> {
  final CalendarRepository repository;

  GetHijriCalendarYear(this.repository);

  @override
  Future<Either<Failure, List<HijriCalendarMonth>>> call(
    CalendarYearParams params,
  ) async {
    return await repository.getCalendarYear(
      year: params.year,
      refresh: params.refresh,
    );
  }
}

class CalendarYearParams extends Equatable {
  final int year;
  final bool refresh;

  const CalendarYearParams({required this.year, this.refresh = false});

  @override
  List<Object?> get props => [year, refresh];
}
