import 'package:equatable/equatable.dart';
import 'package:quranapp/features/audio/domain/entities/recitation_result.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';

abstract class RecitationCheckState extends Equatable {
  const RecitationCheckState();

  @override
  List<Object?> get props => [];
}

class RecitationCheckInitial extends RecitationCheckState {}

class RecitationCheckLoadingSurahs extends RecitationCheckState {}

class RecitationCheckSurahsLoaded extends RecitationCheckState {
  final List<Surah> surahs;
  final Surah? selectedSurah;
  final int? selectedAyah;
  final List<int> completedAyahs;
  final List<int> ayahWordCounts;
  final List<String> ayahTexts;

  const RecitationCheckSurahsLoaded({
    required this.surahs,
    this.selectedSurah,
    this.selectedAyah,
    this.completedAyahs = const [],
    this.ayahWordCounts = const [],
    this.ayahTexts = const [],
  });

  RecitationCheckSurahsLoaded copyWith({
    List<Surah>? surahs,
    Surah? selectedSurah,
    int? selectedAyah,
    List<int>? completedAyahs,
    List<int>? ayahWordCounts,
    List<String>? ayahTexts,
  }) {
    return RecitationCheckSurahsLoaded(
      surahs: surahs ?? this.surahs,
      selectedSurah: selectedSurah ?? this.selectedSurah,
      selectedAyah: selectedAyah ?? this.selectedAyah,
      completedAyahs: completedAyahs ?? this.completedAyahs,
      ayahWordCounts: ayahWordCounts ?? this.ayahWordCounts,
      ayahTexts: ayahTexts ?? this.ayahTexts,
    );
  }

  @override
  List<Object?> get props => [
    surahs,
    selectedSurah,
    selectedAyah,
    completedAyahs,
    ayahWordCounts,
    ayahTexts,
  ];
}

class RecitationCheckRecording extends RecitationCheckState {
  final List<Surah> surahs;
  final Surah selectedSurah;
  final int selectedAyah;
  final List<int> completedAyahs;
  final List<int> ayahWordCounts;
  final List<String> ayahTexts;

  const RecitationCheckRecording({
    required this.surahs,
    required this.selectedSurah,
    required this.selectedAyah,
    required this.completedAyahs,
    required this.ayahWordCounts,
    required this.ayahTexts,
  });

  @override
  List<Object?> get props => [
    surahs,
    selectedSurah,
    selectedAyah,
    completedAyahs,
    ayahWordCounts,
    ayahTexts,
  ];
}

class RecitationCheckProcessing extends RecitationCheckState {
  final List<Surah> surahs;
  final Surah selectedSurah;
  final int selectedAyah;
  final List<int> completedAyahs;
  final List<int> ayahWordCounts;
  final List<String> ayahTexts;

  const RecitationCheckProcessing({
    required this.surahs,
    required this.selectedSurah,
    required this.selectedAyah,
    required this.completedAyahs,
    required this.ayahWordCounts,
    required this.ayahTexts,
  });

  @override
  List<Object?> get props => [
    surahs,
    selectedSurah,
    selectedAyah,
    completedAyahs,
    ayahWordCounts,
    ayahTexts,
  ];
}

class RecitationCheckSuccess extends RecitationCheckState {
  final List<Surah> surahs;
  final Surah selectedSurah;
  final int selectedAyah;
  final RecitationResult result;
  final List<int> completedAyahs;
  final List<int> ayahWordCounts;
  final List<String> ayahTexts;

  const RecitationCheckSuccess({
    required this.surahs,
    required this.selectedSurah,
    required this.selectedAyah,
    required this.result,
    required this.completedAyahs,
    required this.ayahWordCounts,
    required this.ayahTexts,
  });

  @override
  List<Object?> get props => [
    surahs,
    selectedSurah,
    selectedAyah,
    result,
    completedAyahs,
    ayahWordCounts,
    ayahTexts,
  ];
}

class RecitationCheckFailure extends RecitationCheckState {
  final List<Surah> surahs;
  final Surah? selectedSurah;
  final int? selectedAyah;
  final String message;
  final List<int> completedAyahs;
  final List<int> ayahWordCounts;
  final List<String> ayahTexts;

  const RecitationCheckFailure({
    required this.surahs,
    this.selectedSurah,
    this.selectedAyah,
    required this.message,
    this.completedAyahs = const [],
    this.ayahWordCounts = const [],
    this.ayahTexts = const [],
  });

  @override
  List<Object?> get props => [
    surahs,
    selectedSurah,
    selectedAyah,
    message,
    completedAyahs,
    ayahWordCounts,
    ayahTexts,
  ];
}
