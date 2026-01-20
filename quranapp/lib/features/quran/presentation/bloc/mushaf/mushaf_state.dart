import 'package:equatable/equatable.dart';
import 'package:quranapp/features/quran/domain/entities/mushaf_session.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/domain/entities/surah_page_range.dart';

enum MushafStatus { initial, loading, loaded, error }

class MushafState extends Equatable {
  final MushafStatus status;
  final Surah? selectedSurah;
  final int currentPage;
  final SurahPageRange? pageRange;
  final Map<int, List<Verse>> loadedPages;
  final bool isTextVisible;
  final MushafSession session;
  final bool isRecording;
  final bool isProcessing;
  final String? errorMessage;

  const MushafState({
    this.status = MushafStatus.initial,
    this.selectedSurah,
    this.currentPage = 1,
    this.pageRange,
    this.loadedPages = const {},
    this.isTextVisible = true,
    this.session = const MushafSession(surahId: 0),
    this.isRecording = false,
    this.isProcessing = false,
    this.errorMessage,
  });

  /// Check if current page is within surah's page range
  bool get isPageInRange {
    if (pageRange == null) return false;
    return currentPage >= pageRange!.firstPage &&
        currentPage <= pageRange!.lastPage;
  }

  /// Get verses for current page
  List<Verse> get currentPageVerses => loadedPages[currentPage] ?? [];

  /// Check if we can navigate to previous page (within surah)
  bool get canGoPrevious {
    if (pageRange == null) return false;
    return currentPage > pageRange!.firstPage;
  }

  /// Check if we can navigate to next page (within surah)
  bool get canGoNext {
    if (pageRange == null) return false;
    return currentPage < pageRange!.lastPage;
  }

  MushafState copyWith({
    MushafStatus? status,
    Surah? selectedSurah,
    int? currentPage,
    SurahPageRange? pageRange,
    Map<int, List<Verse>>? loadedPages,
    bool? isTextVisible,
    MushafSession? session,
    bool? isRecording,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return MushafState(
      status: status ?? this.status,
      selectedSurah: selectedSurah ?? this.selectedSurah,
      currentPage: currentPage ?? this.currentPage,
      pageRange: pageRange ?? this.pageRange,
      loadedPages: loadedPages ?? this.loadedPages,
      isTextVisible: isTextVisible ?? this.isTextVisible,
      session: session ?? this.session,
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedSurah,
    currentPage,
    pageRange,
    loadedPages,
    isTextVisible,
    session,
    isRecording,
    isProcessing,
    errorMessage,
  ];
}
