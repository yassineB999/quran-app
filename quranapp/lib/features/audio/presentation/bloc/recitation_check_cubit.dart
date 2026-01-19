import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/audio/domain/usecases/check_recitation.dart';
import 'package:quranapp/features/audio/presentation/bloc/recitation_check_state.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/domain/usecases/get_all_surahs.dart';
import 'package:quranapp/features/quran/domain/usecases/get_surah_detail.dart';

class RecitationCheckCubit extends Cubit<RecitationCheckState> {
  final GetAllSurahs getAllSurahs;
  final GetSurahDetail getSurahDetail;
  final CheckRecitation checkRecitation;

  RecitationCheckCubit({
    required this.getAllSurahs,
    required this.getSurahDetail,
    required this.checkRecitation,
  }) : super(RecitationCheckInitial());

  Future<void> loadSurahs() async {
    emit(RecitationCheckLoadingSurahs());
    final result = await getAllSurahs(NoParams());
    await result.fold(
      (failure) async => emit(
        RecitationCheckFailure(surahs: const [], message: failure.message),
      ),
      (surahs) async {
        if (surahs.isEmpty) {
          emit(RecitationCheckSurahsLoaded(surahs: surahs));
          return;
        }
        final selectedSurah = surahs.first;
        final loaded = RecitationCheckSurahsLoaded(
          surahs: surahs,
          selectedSurah: selectedSurah,
          selectedAyah: 1,
          completedAyahs: const [],
          ayahWordCounts: _defaultWordCounts(selectedSurah.versesCount),
          ayahTexts: _defaultAyahTexts(selectedSurah.versesCount),
        );
        emit(loaded);
        await _loadSurahDetail(
          surahs: surahs,
          selectedSurah: selectedSurah,
          selectedAyah: 1,
          completedAyahs: const [],
        );
      },
    );
  }

  Future<void> selectSurah(Surah surah) async {
    List<Surah> surahs = [];
    if (state is RecitationCheckSurahsLoaded) {
      surahs = (state as RecitationCheckSurahsLoaded).surahs;
    } else if (state is RecitationCheckSuccess) {
      surahs = (state as RecitationCheckSuccess).surahs;
    } else if (state is RecitationCheckFailure) {
      surahs = (state as RecitationCheckFailure).surahs;
    } else if (state is RecitationCheckRecording) {
      surahs = (state as RecitationCheckRecording).surahs;
    } else if (state is RecitationCheckProcessing) {
      surahs = (state as RecitationCheckProcessing).surahs;
    }

    emit(
      RecitationCheckSurahsLoaded(
        surahs: surahs,
        selectedSurah: surah,
        selectedAyah: 1,
        completedAyahs: const [],
        ayahWordCounts: _defaultWordCounts(surah.versesCount),
        ayahTexts: _defaultAyahTexts(surah.versesCount),
      ),
    );

    await _loadSurahDetail(
      surahs: surahs,
      selectedSurah: surah,
      selectedAyah: 1,
      completedAyahs: const [],
    );
  }

  void selectAyah(int ayah) {
    if (state is RecitationCheckSurahsLoaded) {
      final currentState = state as RecitationCheckSurahsLoaded;
      emit(currentState.copyWith(selectedAyah: ayah));
    } else if (state is RecitationCheckSuccess) {
      final currentState = state as RecitationCheckSuccess;
      emit(
        RecitationCheckSurahsLoaded(
          surahs: currentState.surahs,
          selectedSurah: currentState.selectedSurah,
          selectedAyah: ayah,
          completedAyahs: currentState.completedAyahs,
          ayahWordCounts: currentState.ayahWordCounts,
          ayahTexts: currentState.ayahTexts,
        ),
      );
    } else if (state is RecitationCheckFailure) {
      final currentState = state as RecitationCheckFailure;
      if (currentState.selectedSurah == null) {
        return;
      }
      emit(
        RecitationCheckSurahsLoaded(
          surahs: currentState.surahs,
          selectedSurah: currentState.selectedSurah,
          selectedAyah: ayah,
          completedAyahs: currentState.completedAyahs,
          ayahWordCounts: currentState.ayahWordCounts,
          ayahTexts: currentState.ayahTexts,
        ),
      );
    }
  }

  void startRecording() {
    if (state is RecitationCheckSurahsLoaded) {
      final currentState = state as RecitationCheckSurahsLoaded;
      if (currentState.selectedSurah != null &&
          currentState.selectedAyah != null) {
        emit(
          RecitationCheckRecording(
            surahs: currentState.surahs,
            selectedSurah: currentState.selectedSurah!,
            selectedAyah: currentState.selectedAyah!,
            completedAyahs: currentState.completedAyahs,
            ayahWordCounts: currentState.ayahWordCounts,
            ayahTexts: currentState.ayahTexts,
          ),
        );
      }
    } else if (state is RecitationCheckSuccess) {
      final currentState = state as RecitationCheckSuccess;
      emit(
        RecitationCheckRecording(
          surahs: currentState.surahs,
          selectedSurah: currentState.selectedSurah,
          selectedAyah: currentState.selectedAyah,
          completedAyahs: currentState.completedAyahs,
          ayahWordCounts: currentState.ayahWordCounts,
          ayahTexts: currentState.ayahTexts,
        ),
      );
    } else if (state is RecitationCheckFailure) {
      final currentState = state as RecitationCheckFailure;
      if (currentState.selectedSurah == null ||
          currentState.selectedAyah == null) {
        return;
      }
      emit(
        RecitationCheckRecording(
          surahs: currentState.surahs,
          selectedSurah: currentState.selectedSurah!,
          selectedAyah: currentState.selectedAyah!,
          completedAyahs: currentState.completedAyahs,
          ayahWordCounts: currentState.ayahWordCounts,
          ayahTexts: currentState.ayahTexts,
        ),
      );
    }
  }

  void stopRecording(String? filePath) async {
    if (state is RecitationCheckRecording) {
      final currentState = state as RecitationCheckRecording;

      if (filePath == null) {
        emit(
          RecitationCheckSurahsLoaded(
            surahs: currentState.surahs,
            selectedSurah: currentState.selectedSurah,
            selectedAyah: currentState.selectedAyah,
            completedAyahs: currentState.completedAyahs,
            ayahWordCounts: currentState.ayahWordCounts,
            ayahTexts: currentState.ayahTexts,
          ),
        );
        return;
      }

      emit(
        RecitationCheckProcessing(
          surahs: currentState.surahs,
          selectedSurah: currentState.selectedSurah,
          selectedAyah: currentState.selectedAyah,
          completedAyahs: currentState.completedAyahs,
          ayahWordCounts: currentState.ayahWordCounts,
          ayahTexts: currentState.ayahTexts,
        ),
      );

      final result = await checkRecitation(
        CheckRecitationParams(
          filePath: filePath,
          surahId: currentState.selectedSurah.number,
          ayahId: currentState.selectedAyah,
        ),
      );

      result.fold(
        (failure) => emit(
          RecitationCheckFailure(
            surahs: currentState.surahs,
            selectedSurah: currentState.selectedSurah,
            selectedAyah: currentState.selectedAyah,
            message: failure.message,
            completedAyahs: currentState.completedAyahs,
            ayahWordCounts: currentState.ayahWordCounts,
            ayahTexts: currentState.ayahTexts,
          ),
        ),
        (recitationResult) {
          var updatedCompleted = currentState.completedAyahs;
          var nextAyah = currentState.selectedAyah;
          if (recitationResult.success) {
            final set = {
              ...currentState.completedAyahs,
              currentState.selectedAyah,
            };
            updatedCompleted = set.toList()..sort();
            if (currentState.selectedAyah <
                currentState.selectedSurah.versesCount) {
              nextAyah = currentState.selectedAyah + 1;
            }
          }
          emit(
            RecitationCheckSuccess(
              surahs: currentState.surahs,
              selectedSurah: currentState.selectedSurah,
              selectedAyah: nextAyah,
              result: recitationResult,
              completedAyahs: updatedCompleted,
              ayahWordCounts: currentState.ayahWordCounts,
              ayahTexts: currentState.ayahTexts,
            ),
          );
        },
      );
    }
  }

  List<int> _defaultWordCounts(int count) {
    if (count <= 0) return const [];
    return List<int>.filled(count, 6);
  }

  List<String> _defaultAyahTexts(int count) {
    if (count <= 0) return const [];
    return List<String>.filled(count, '');
  }

  int _wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 1;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  Future<void> _loadSurahDetail({
    required List<Surah> surahs,
    required Surah selectedSurah,
    required int selectedAyah,
    required List<int> completedAyahs,
  }) async {
    final result = await getSurahDetail(
      GetSurahDetailParams(id: selectedSurah.number),
    );

    List<int> wordCounts = _defaultWordCounts(selectedSurah.versesCount);
    List<String> ayahTexts = _defaultAyahTexts(selectedSurah.versesCount);
    result.fold((failure) => null, (detail) {
      if (detail.verses.isNotEmpty) {
        wordCounts = detail.verses.map((v) => _wordCount(v.text)).toList();
        ayahTexts = detail.verses.map((v) => v.text).toList();
      }
    });

    emit(
      RecitationCheckSurahsLoaded(
        surahs: surahs,
        selectedSurah: selectedSurah,
        selectedAyah: selectedAyah,
        completedAyahs: completedAyahs,
        ayahWordCounts: wordCounts,
        ayahTexts: ayahTexts,
      ),
    );
  }
}
