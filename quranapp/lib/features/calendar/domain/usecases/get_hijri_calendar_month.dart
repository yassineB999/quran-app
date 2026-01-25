import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';
import 'package:quranapp/features/calendar/domain/repositories/calendar_repository.dart';

/// Use case to fetch Hijri calendar data for a specific month.
class GetHijriCalendarMonth
    implements UseCase<HijriCalendarMonth, CalendarMonthParams> {
  final CalendarRepository repository;

  GetHijriCalendarMonth(this.repository);

  @override
  Future<Either<Failure, HijriCalendarMonth>> call(
    CalendarMonthParams params,
  ) async {
    return await repository.getCalendarMonth(
      year: params.year,
      month: params.month,
      refresh: params.refresh,
    );
  }
}

class CalendarMonthParams extends Equatable {
  final int year;
  final int month;
  final bool refresh;

  const CalendarMonthParams({
    required this.year,
    required this.month,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [year, month, refresh];
}
