import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith_book.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith_edition.dart';
import 'package:quranapp/features/hadith/domain/usecases/get_hadith_by_edition.dart';
import 'package:quranapp/features/hadith/domain/usecases/get_hadith_editions.dart';
import 'package:quranapp/features/hadith/presentation/bloc/hadith_event.dart';
import 'package:quranapp/features/hadith/presentation/bloc/hadith_state.dart';

class HadithBloc extends Bloc<HadithEvent, HadithState> {
  final GetHadithEditions getHadithEditions;
  final GetHadithByEdition getHadithByEdition;

  HadithBloc({
    required this.getHadithEditions,
    required this.getHadithByEdition,
  }) : super(HadithInitial()) {
    on<GetHadithEditionsEvent>(_onGetEditions);
    on<GetHadithsByEditionEvent>(_onGetHadithsByEdition);
    on<GetHadithsByBookEvent>(_onGetHadithsByBook);
  }

  Future<void> _onGetEditions(
    GetHadithEditionsEvent event,
    Emitter<HadithState> emit,
  ) async {
    emit(HadithLoading());
    final result = await getHadithEditions(NoParams());
    result.fold((failure) => emit(HadithError(failure.message)), (editions) {
      // Group by collection
      final Map<String, List<HadithEdition>> grouped = {};
      for (var edition in editions) {
        // Normalize collection name if needed, assuming 'collection' field is consistent
        final key = edition.collection;
        if (!grouped.containsKey(key)) {
          grouped[key] = [];
        }
        grouped[key]!.add(edition);
      }

      final List<HadithBook> books = grouped.entries
          .map((entry) {
            final name = entry.key;
            final List<HadithEdition> list = entry.value;

            HadithEdition? arabic;
            HadithEdition? english;

            // Simple heuristic for language - checks name or language field
            // Improve this loop to be more robust
            for (var e in list) {
              final lang = e.language.toLowerCase();
              if (lang.contains('arabic') ||
                  lang.contains('ara') ||
                  e.id.startsWith('ara-')) {
                // Prefer the one without '1' if multiple (e.g. ara-bukhari vs ara-bukhari1)
                if (arabic == null || e.id.length < arabic.id.length) {
                  arabic = e;
                }
              } else if (lang.contains('english') ||
                  lang.contains('eng') ||
                  e.id.startsWith('eng-') ||
                  e.id.startsWith('en-')) {
                english = e;
              }
            }

            return HadithBook(
              name: name,
              arabicEdition: arabic,
              englishEdition: english,
            );
          })
          .where((b) => b.arabicEdition != null || b.englishEdition != null)
          .toList();

      emit(HadithBooksLoaded(books));
    });
  }

  Future<void> _onGetHadithsByBook(
    GetHadithsByBookEvent event,
    Emitter<HadithState> emit,
  ) async {
    emit(HadithLoading());

    // Fetch both asynchronously
    List<Hadith> arabicHadiths = [];
    List<Hadith> englishHadiths = [];
    String? errorMessage;

    if (event.arabicEditionId != null) {
      final result = await getHadithByEdition(
        GetHadithByEditionParams(editionId: event.arabicEditionId!),
      );
      result.fold((l) => errorMessage = l.message, (r) => arabicHadiths = r);
    }

    if (errorMessage != null && event.englishEditionId == null) {
      emit(HadithError(errorMessage!));
      return;
    }

    if (event.englishEditionId != null) {
      final result = await getHadithByEdition(
        GetHadithByEditionParams(editionId: event.englishEditionId!),
      );
      result.fold(
        // If english fails but arabic succeeded, we might still want to show arabic?
        // For now let's just log or ignore if secondary fails, or error if primary fails.
        // Let's assume we want at least one.
        (l) => errorMessage ??= l.message,
        (r) => englishHadiths = r,
      );
    }

    if (arabicHadiths.isEmpty && englishHadiths.isEmpty) {
      emit(HadithError(errorMessage ?? 'No hadiths found'));
      return;
    }

    // Merge logic
    // Assuming hadiths match by 'number'.
    // Create a map of English hadiths by number
    final englishMap = {for (var h in englishHadiths) h.number: h};

    final List<Hadith> merged = arabicHadiths.map((h) {
      final eng = englishMap[h.number];
      return Hadith(
        number: h.number,
        text: h.text,
        englishText:
            eng?.text, // Use the 'text' of the english hadith as 'englishText'
        narrator: h.narrator ?? eng?.narrator,
        grade: h.grade ?? eng?.grade,
        chapter: h.chapter ?? eng?.chapter,
      );
    }).toList();

    // If we only have English (edge case)
    if (merged.isEmpty && englishHadiths.isNotEmpty) {
      // Convert English only to Hadith objects with text as primary?
      // Or map English to englishText?
      // User requested Arabic first then English. If no Arabic, just show English in primary text?
      // Let's stick to valid Arabic preferred.
      emit(HadithsLoaded(englishHadiths, event.englishEditionId!));
      return;
    }

    emit(HadithsLoaded(merged, event.bookId));
  }

  Future<void> _onGetHadithsByEdition(
    GetHadithsByEditionEvent event,
    Emitter<HadithState> emit,
  ) async {
    emit(HadithLoading());
    final result = await getHadithByEdition(
      GetHadithByEditionParams(editionId: event.editionId),
    );
    result.fold(
      (failure) => emit(HadithError(failure.message)),
      (hadiths) => emit(HadithsLoaded(hadiths, event.editionId)),
    );
  }
}
