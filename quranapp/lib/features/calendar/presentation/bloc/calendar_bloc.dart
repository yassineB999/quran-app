import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';
import 'package:quranapp/features/calendar/domain/usecases/get_hijri_calendar_month.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_event.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetHijriCalendarMonth getHijriCalendarMonth;

  int _currentYear;
  int _currentMonth;

  CalendarBloc({required this.getHijriCalendarMonth})
    : _currentYear = DateTime.now().year,
      _currentMonth = DateTime.now().month,
      super(const CalendarInitial()) {
    on<LoadCalendarMonth>(_onLoadCalendarMonth);
    on<PreviousMonth>(_onPreviousMonth);
    on<NextMonth>(_onNextMonth);
    on<GoToToday>(_onGoToToday);
  }

  Future<void> _onLoadCalendarMonth(
    LoadCalendarMonth event,
    Emitter<CalendarState> emit,
  ) async {
    _currentYear = event.year;
    _currentMonth = event.month;

    final currentState = state;
    Map<String, HijriCalendarMonth> currentCache = {};
    if (currentState is CalendarLoaded) {
      currentCache = Map.from(currentState.cachedMonths);
    }

    final cacheKey = '${event.year}-${event.month}';

    // If we have data, emit it immediately (or keep showing it if already there)
    // We also want to indicate loading if refresh is true or data missing
    if (currentCache.containsKey(cacheKey) && !event.refresh) {
      emit(
        CalendarLoaded(
          cachedMonths: currentCache,
          currentYear: event.year,
          currentMonth: event.month,
          today: DateTime.now(),
          isLoading: false,
        ),
      );
      return;
    }

    // Emit loading state but KEEP previous data if available (Loaded state with isLoading=true)
    // If it was Initial or Error, we might need a dedicated Loading state or just empty Loaded
    if (currentState is CalendarLoaded) {
      emit(
        CalendarLoaded(
          cachedMonths: currentCache,
          currentYear: event.year,
          currentMonth: event.month,
          today: currentState.today,
          isLoading: true,
        ),
      );
    } else {
      emit(CalendarLoading(year: event.year, month: event.month));
    }

    final result = await getHijriCalendarMonth(
      CalendarMonthParams(
        year: event.year,
        month: event.month,
        refresh: event.refresh,
      ),
    );

    result.fold(
      (failure) {
        // If we had data, maybe revert to it or show error?
        // For now, standard error behavior if we fail distinct load
        emit(
          CalendarError(
            message: failure.message,
            year: event.year,
            month: event.month,
          ),
        );
      },
      (calendarMonth) {
        currentCache[cacheKey] = calendarMonth;
        emit(
          CalendarLoaded(
            cachedMonths: currentCache,
            currentYear: event.year,
            currentMonth: event.month,
            today: DateTime.now(),
            isLoading: false,
          ),
        );
      },
    );
  }

  Future<void> _onPreviousMonth(
    PreviousMonth event,
    Emitter<CalendarState> emit,
  ) async {
    int newMonth = _currentMonth - 1;
    int newYear = _currentYear;

    if (newMonth < 1) {
      newMonth = 12;
      newYear -= 1;
    }

    add(LoadCalendarMonth(year: newYear, month: newMonth));
  }

  Future<void> _onNextMonth(
    NextMonth event,
    Emitter<CalendarState> emit,
  ) async {
    int newMonth = _currentMonth + 1;
    int newYear = _currentYear;

    if (newMonth > 12) {
      newMonth = 1;
      newYear += 1;
    }

    add(LoadCalendarMonth(year: newYear, month: newMonth));
  }

  Future<void> _onGoToToday(
    GoToToday event,
    Emitter<CalendarState> emit,
  ) async {
    final now = DateTime.now();
    add(LoadCalendarMonth(year: now.year, month: now.month));
  }
}
