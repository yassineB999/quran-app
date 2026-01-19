import 'package:equatable/equatable.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';

enum ReaderStatus { initial, loading, loaded, failure }

class QuranReaderState extends Equatable {
  final ReaderStatus status;
  final Map<int, List<Verse>> pages; // Cache: PageNumber -> Verses
  final String? errorMessage;
  final int? lastReadPage; // Persisted last page

  const QuranReaderState({
    this.status = ReaderStatus.initial,
    this.pages = const {},
    this.errorMessage,
    this.lastReadPage,
  });

  QuranReaderState copyWith({
    ReaderStatus? status,
    Map<int, List<Verse>>? pages,
    String? errorMessage,
    int? lastReadPage,
  }) {
    return QuranReaderState(
      status: status ?? this.status,
      pages: pages ?? this.pages,
      errorMessage: errorMessage ?? this.errorMessage,
      lastReadPage: lastReadPage ?? this.lastReadPage,
    );
  }

  @override
  List<Object?> get props => [status, pages, errorMessage, lastReadPage];
}
