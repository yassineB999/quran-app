import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/network/connectivity_service.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';
import 'package:quranapp/features/calendar/domain/usecases/get_hijri_calendar_month.dart';
import 'package:quranapp/features/calendar/domain/usecases/get_hijri_calendar_year.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_event.dart';
import 'package:quranapp/features/calendar/presentation/bloc/calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final GetHijriCalendarMonth getHijriCalendarMonth;
  final GetHijriCalendarYear getHijriCalendarYear;

  int _currentYear;
  int _currentMonth;
  final ConnectivityService connectivityService;
  StreamSubscription? _connectivitySubscription;

  CalendarBloc({
    required this.getHijriCalendarMonth,
    required this.getHijriCalendarYear,
    required this.connectivityService,
  }) : _currentYear = DateTime.now().year,
       _currentMonth = DateTime.now().month,
       super(const CalendarInitial()) {
    on<LoadCalendarMonth>(_onLoadCalendarMonth);
    on<PreviousMonth>(_onPreviousMonth);
    on<NextMonth>(_onNextMonth);
    on<GoToToday>(_onGoToToday);
    _setupAutoRetry();
  }

  void _setupAutoRetry() {
    _connectivitySubscription = connectivityService.stateStream.listen((state) {
      if (state is ConnectivityOnline) {
        if (this.state is CalendarError) {
          final errorState = this.state as CalendarError;
          add(
            LoadCalendarMonth(year: errorState.year, month: errorState.month),
          );
        }
      }
    });
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

    // 1. Check Cache
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

    // 2. Emit Loading
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

    // 3. Optimization: Fetch Entire Year if cache miss
    // If the user is requesting specific month and it's missing,
    // we fetch the WHOLE year to populate cache for adjacent months.

    // Check if we should fetch year or just month.
    // Usually fetching year is better unless we explicitly want only one month refresh.
    // Let's assume year fetch is standard for navigation.

    final result = await getHijriCalendarYear(
      CalendarYearParams(year: event.year, refresh: event.refresh),
    );

    result.fold(
      (failure) {
        // Fallback or Error
        // If year fetch fails, we could try single month fetch?
        // Or just show error. Showing error is safer.
        emit(
          CalendarError(
            message: failure.message,
            year: event.year,
            month: event.month,
          ),
        );
      },
      (monthsList) {
        // Populate cache with ALL returned months
        for (final monthData in monthsList) {
          final key = '${monthData.gregorianYear}-${monthData.gregorianMonth}';
          currentCache[key] = monthData;
        }

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

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
