import 'package:equatable/equatable.dart';

/// Represents the page range for a surah in the Mushaf.
/// Contains the first and last page numbers where this surah appears.
class SurahPageRange extends Equatable {
  final int surahNumber;
  final int firstPage;
  final int lastPage;

  const SurahPageRange({
    required this.surahNumber,
    required this.firstPage,
    required this.lastPage,
  });

  /// Returns the total number of pages this surah spans
  int get pageCount => lastPage - firstPage + 1;

  @override
  List<Object?> get props => [surahNumber, firstPage, lastPage];
}
