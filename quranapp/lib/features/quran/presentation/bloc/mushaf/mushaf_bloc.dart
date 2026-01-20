import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/features/audio/domain/usecases/check_recitation.dart';
import 'package:quranapp/features/quran/domain/entities/mushaf_session.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';
import 'package:quranapp/features/quran/domain/usecases/get_quran_page.dart';
import 'package:quranapp/features/quran/domain/usecases/get_surah_page_range.dart';
import 'package:quranapp/features/quran/domain/usecases/get_surah_detail.dart';
import 'package:quranapp/features/quran/presentation/bloc/mushaf/mushaf_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/mushaf/mushaf_state.dart';

class MushafBloc extends Bloc<MushafEvent, MushafState> {
  final GetSurahPageRange getSurahPageRange;
  final GetQuranPage getQuranPage;
  final GetSurahDetail getSurahDetail;
  final CheckRecitation checkRecitation;
  final QuranRepository quranRepository;

  MushafBloc({
    required this.getSurahPageRange,
    required this.getQuranPage,
    required this.getSurahDetail,
    required this.checkRecitation,
    required this.quranRepository,
  }) : super(const MushafState()) {
    on<LoadSurahForMushaf>(_onLoadSurah);
    on<LoadMushafPage>(_onLoadPage);
    on<NavigateToMushafPage>(_onNavigatePage);
    on<ToggleTextVisibility>(_onToggleVisibility);
    on<StartMushafRecitation>(_onStartRecitation);
    on<StopMushafRecitation>(_onStopRecitation);
    on<SubmitMushafRecitationAudio>(_onSubmitAudio);
    on<AdvanceToNextAyah>(_onAdvanceAyah);
    on<UpdateCurrentAyah>(_onUpdateCurrentAyah);
    on<MarkAyahComplete>(_onMarkAyahComplete);
  }

  Future<void> _onLoadSurah(
    LoadSurahForMushaf event,
    Emitter<MushafState> emit,
  ) async {
    emit(state.copyWith(status: MushafStatus.loading));

    // First, get the page range for this surah
    final pageRangeResult = await getSurahPageRange(event.surahId);

    await pageRangeResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: MushafStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
      (pageRange) async {
        // Also load the surah details for name, etc.
        final surahResult = await getSurahDetail(
          GetSurahDetailParams(id: event.surahId),
        );

        final surah = surahResult.fold((l) => null, (r) => r);

        // Initialize session for this surah
        final session = MushafSession(
          surahId: event.surahId,
          currentAyahNumberInSurah: 1,
        );

        emit(
          state.copyWith(
            status: MushafStatus.loaded,
            selectedSurah: surah,
            pageRange: pageRange,
            currentPage: pageRange.firstPage,
            session: session,
            loadedPages: {}, // Clear old pages
          ),
        );

        // Load the first page
        add(LoadMushafPage(pageRange.firstPage));
      },
    );
  }

  Future<void> _onLoadPage(
    LoadMushafPage event,
    Emitter<MushafState> emit,
  ) async {
    // Skip if already loaded
    if (state.loadedPages.containsKey(event.pageNumber)) {
      return;
    }

    final result = await getQuranPage(event.pageNumber);

    result.fold(
      (failure) {
        // Don't set error state, just log it
      },
      (verses) {
        final updatedPages = Map.of(state.loadedPages);
        updatedPages[event.pageNumber] = verses;
        emit(state.copyWith(loadedPages: updatedPages));
      },
    );
  }

  void _onNavigatePage(NavigateToMushafPage event, Emitter<MushafState> emit) {
    if (state.pageRange == null) return;

    // Clamp page to valid range
    final page = event.pageNumber.clamp(
      state.pageRange!.firstPage,
      state.pageRange!.lastPage,
    );

    emit(state.copyWith(currentPage: page));

    // Load the page if not already loaded
    if (!state.loadedPages.containsKey(page)) {
      add(LoadMushafPage(page));
    }
  }

  void _onToggleVisibility(
    ToggleTextVisibility event,
    Emitter<MushafState> emit,
  ) {
    // CRITICAL: Session state is preserved across toggles
    // Only the visibility changes
    emit(state.copyWith(isTextVisible: !state.isTextVisible));
  }

  void _onStartRecitation(
    StartMushafRecitation event,
    Emitter<MushafState> emit,
  ) {
    // Activate session and start recording
    final updatedSession = state.session.copyWith(isActive: true);
    emit(state.copyWith(session: updatedSession, isRecording: true));
  }

  void _onStopRecitation(
    StopMushafRecitation event,
    Emitter<MushafState> emit,
  ) {
    emit(state.copyWith(isRecording: false));
    // Note: Session stays active so user can resume
  }

  Future<void> _onSubmitAudio(
    SubmitMushafRecitationAudio event,
    Emitter<MushafState> emit,
  ) async {
    if (state.selectedSurah == null) return;

    emit(state.copyWith(isProcessing: true, isRecording: false));

    final result = await checkRecitation(
      CheckRecitationParams(
        filePath: event.filePath,
        surahId: state.selectedSurah!.number,
        ayahId: state.session.currentAyahNumberInSurah,
      ),
    );

    result.fold(
      (failure) {
        emit(
          state.copyWith(isProcessing: false, errorMessage: failure.message),
        );
      },
      (recitationResult) {
        final currentAyah = state.session.currentAyahNumberInSurah;
        final feedback = AyahWordFeedback(isCorrect: recitationResult.success);

        final updatedFeedback = Map.of(state.session.ayahFeedback);
        updatedFeedback[currentAyah] = feedback;

        var updatedSession = state.session.copyWith(
          ayahFeedback: updatedFeedback,
        );

        // If correct, advance to next ayah
        if (recitationResult.success) {
          final completedAyahs = {...state.session.completedAyahs, currentAyah};
          updatedSession = updatedSession.copyWith(
            completedAyahs: completedAyahs,
            currentAyahNumberInSurah: currentAyah + 1,
          );
        }

        emit(state.copyWith(isProcessing: false, session: updatedSession));
      },
    );
  }

  void _onAdvanceAyah(AdvanceToNextAyah event, Emitter<MushafState> emit) {
    final newSession = state.session.advanceAyah();
    emit(state.copyWith(session: newSession));
  }

  void _onUpdateCurrentAyah(
    UpdateCurrentAyah event,
    Emitter<MushafState> emit,
  ) {
    final updatedSession = state.session.copyWith(
      currentAyahNumberInSurah: event.ayahNumber,
    );
    emit(state.copyWith(session: updatedSession));
  }

  void _onMarkAyahComplete(MarkAyahComplete event, Emitter<MushafState> emit) {
    final feedback = AyahWordFeedback(isCorrect: event.isCorrect);
    final updatedFeedback = Map.of(state.session.ayahFeedback);
    updatedFeedback[event.ayahNumber] = feedback;

    var completedAyahs = state.session.completedAyahs;
    if (event.isCorrect) {
      completedAyahs = {...completedAyahs, event.ayahNumber};
    }

    final updatedSession = state.session.copyWith(
      ayahFeedback: updatedFeedback,
      completedAyahs: completedAyahs,
    );

    emit(state.copyWith(session: updatedSession));
  }
}
