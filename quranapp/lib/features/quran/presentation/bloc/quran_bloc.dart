import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/network/connectivity_service.dart';
import 'package:quranapp/features/quran/domain/usecases/get_surah_detail.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_state.dart';

import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/usecases/get_all_surahs.dart';

/// BLoC for managing Quran-related state.
///
/// Following clean architecture, this BLoC:
/// - Emits [Failure] objects directly in [QuranError] state
/// - Lets the presentation layer handle error message localization
/// - Supports auto-retry when connectivity is restored
class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final GetSurahDetail getSurahDetail;
  final GetAllSurahs getAllSurahs;
  final ConnectivityService connectivityService;
  StreamSubscription? _connectivitySubscription;

  QuranBloc({
    required this.getSurahDetail,
    required this.getAllSurahs,
    required this.connectivityService,
  }) : super(QuranInitial()) {
    on<GetSurahDetailEvent>(_onGetSurahDetail);
    on<GetAllSurahsEvent>(_onGetAllSurahs);
    _setupAutoRetry();
  }

  /// Auto-retry when reconnecting after a network error
  void _setupAutoRetry() {
    _connectivitySubscription = connectivityService.stateStream.listen((state) {
      if (state is ConnectivityOnline && this.state is QuranError) {
        // Auto-reload last failed request
        add(GetAllSurahsEvent());
      }
    });
  }

  Future<void> _onGetAllSurahs(
    GetAllSurahsEvent event,
    Emitter<QuranState> emit,
  ) async {
    emit(QuranLoading());
    final result = await getAllSurahs(NoParams());
    emit(
      result.fold(
        (failure) => QuranError(failure: failure),
        (surahs) => QuranListLoaded(surahs: surahs),
      ),
    );
  }

  Future<void> _onGetSurahDetail(
    GetSurahDetailEvent event,
    Emitter<QuranState> emit,
  ) async {
    emit(QuranLoading());
    final result = await getSurahDetail(GetSurahDetailParams(id: event.id));
    emit(
      result.fold(
        (failure) => QuranError(failure: failure),
        (surah) => QuranLoaded(surah: surah),
      ),
    );
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
