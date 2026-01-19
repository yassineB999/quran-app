import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/domain/usecases/get_quran_page.dart';
import 'package:quranapp/features/quran/domain/usecases/get_reading_progress.dart';
import 'package:quranapp/features/quran/domain/usecases/save_reading_progress.dart';
import 'package:quranapp/features/quran/presentation/bloc/reader/quran_reader_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/reader/quran_reader_state.dart';

class QuranReaderBloc extends Bloc<QuranReaderEvent, QuranReaderState> {
  final GetQuranPage getQuranPage;
  final SaveReadingProgress saveReadingProgress;
  final GetReadingProgress getReadingProgress;

  QuranReaderBloc({
    required this.getQuranPage,
    required this.saveReadingProgress,
    required this.getReadingProgress,
  }) : super(const QuranReaderState()) {
    on<LoadPageEvent>(_onLoadPage);
    on<SavePageEvent>(_onSavePage);
    on<LoadLastPageEvent>(_onLoadLastPage);
  }

  Future<void> _onLoadPage(
    LoadPageEvent event,
    Emitter<QuranReaderState> emit,
  ) async {
    // If page is already cached, do nothing (or generic refresh if needed)
    if (state.pages.containsKey(event.pageNumber) &&
        state.pages[event.pageNumber]!.isNotEmpty) {
      return;
    }

    emit(state.copyWith(status: ReaderStatus.loading));

    final result = await getQuranPage(event.pageNumber);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ReaderStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (verses) {
        final updatedPages = Map<int, List<Verse>>.from(state.pages);
        updatedPages[event.pageNumber] = verses;

        emit(state.copyWith(status: ReaderStatus.loaded, pages: updatedPages));
      },
    );
  }

  Future<void> _onSavePage(
    SavePageEvent event,
    Emitter<QuranReaderState> emit,
  ) async {
    await saveReadingProgress(event.pageNumber);
    // Optimistically update state
    emit(state.copyWith(lastReadPage: event.pageNumber));
  }

  Future<void> _onLoadLastPage(
    LoadLastPageEvent event,
    Emitter<QuranReaderState> emit,
  ) async {
    final result = await getReadingProgress(NoParams());

    result.fold(
      (failure) => null, // Ignore failure for cache
      (page) {
        if (page != null) {
          emit(state.copyWith(lastReadPage: page));
        }
      },
    );
  }
}
