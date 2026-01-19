import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/quran/domain/usecases/get_surah_detail.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_state.dart';

import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/usecases/get_all_surahs.dart';

class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final GetSurahDetail getSurahDetail;
  final GetAllSurahs getAllSurahs;

  QuranBloc({required this.getSurahDetail, required this.getAllSurahs})
    : super(QuranInitial()) {
    on<GetSurahDetailEvent>(_onGetSurahDetail);
    on<GetAllSurahsEvent>(_onGetAllSurahs);
  }

  Future<void> _onGetAllSurahs(
    GetAllSurahsEvent event,
    Emitter<QuranState> emit,
  ) async {
    emit(QuranLoading());
    final result = await getAllSurahs(NoParams());
    emit(
      result.fold(
        (failure) => QuranError(message: _mapFailureToMessage(failure)),
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
        (failure) => QuranError(message: _mapFailureToMessage(failure)),
        (surah) => QuranLoaded(surah: surah),
      ),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Error';
      case NetworkFailure:
        return 'Connection Error';
      default:
        return 'Unexpected Error';
    }
  }
}
