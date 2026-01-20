import 'package:equatable/equatable.dart';

/// Represents a recitation session state for Mushaf mode.
/// This session persists across text visibility toggles.
class MushafSession extends Equatable {
  final int surahId;
  final int currentAyahNumberInSurah;
  final Set<int> completedAyahs;
  final bool isActive;
  final Map<int, AyahWordFeedback> ayahFeedback;

  const MushafSession({
    required this.surahId,
    this.currentAyahNumberInSurah = 1,
    this.completedAyahs = const {},
    this.isActive = false,
    this.ayahFeedback = const {},
  });

  MushafSession copyWith({
    int? surahId,
    int? currentAyahNumberInSurah,
    Set<int>? completedAyahs,
    bool? isActive,
    Map<int, AyahWordFeedback>? ayahFeedback,
  }) {
    return MushafSession(
      surahId: surahId ?? this.surahId,
      currentAyahNumberInSurah:
          currentAyahNumberInSurah ?? this.currentAyahNumberInSurah,
      completedAyahs: completedAyahs ?? this.completedAyahs,
      isActive: isActive ?? this.isActive,
      ayahFeedback: ayahFeedback ?? this.ayahFeedback,
    );
  }

  /// Creates an empty session for initial state
  static MushafSession empty() => const MushafSession(surahId: 0);

  /// Advances to the next ayah
  MushafSession advanceAyah() {
    return copyWith(
      currentAyahNumberInSurah: currentAyahNumberInSurah + 1,
      completedAyahs: {...completedAyahs, currentAyahNumberInSurah},
    );
  }

  @override
  List<Object?> get props => [
    surahId,
    currentAyahNumberInSurah,
    completedAyahs,
    isActive,
    ayahFeedback,
  ];
}

/// Feedback for individual words in an ayah
class AyahWordFeedback extends Equatable {
  final Set<int> correctWords;
  final Set<int> mistakeWords;
  final List<String> feedbackMessages;
  final bool isCorrect;

  const AyahWordFeedback({
    this.correctWords = const {},
    this.mistakeWords = const {},
    this.feedbackMessages = const [],
    this.isCorrect = false,
  });

  AyahWordFeedback copyWith({
    Set<int>? correctWords,
    Set<int>? mistakeWords,
    List<String>? feedbackMessages,
    bool? isCorrect,
  }) {
    return AyahWordFeedback(
      correctWords: correctWords ?? this.correctWords,
      mistakeWords: mistakeWords ?? this.mistakeWords,
      feedbackMessages: feedbackMessages ?? this.feedbackMessages,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  List<Object?> get props => [
    correctWords,
    mistakeWords,
    feedbackMessages,
    isCorrect,
  ];
}
