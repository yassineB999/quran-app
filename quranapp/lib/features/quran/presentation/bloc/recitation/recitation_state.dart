import 'package:equatable/equatable.dart';
import 'package:quranapp/features/quran/domain/entities/recitation_word.dart';

enum RecitationStatus {
  idle, // Not started
  connecting, // WebSocket connecting
  ready, // Session initialized, ready to start
  reciting, // Actively reciting
  paused, // Recitation paused
  completed, // Reached end of surah
  error, // Error occurred
}

class RecitationState extends Equatable {
  final RecitationStatus status;
  final String? sessionId;
  final int surahId;
  final String surahName;
  final int currentAyah;
  final int currentWordIndex; // Global word index
  final List<RecitationWord> words; // All words with their status
  final int totalAyahs;
  final int totalWords;
  final String? errorMessage;
  final bool isRecording;

  const RecitationState({
    this.status = RecitationStatus.idle,
    this.sessionId,
    this.surahId = 0,
    this.surahName = '',
    this.currentAyah = 1,
    this.currentWordIndex = 0,
    this.words = const [],
    this.totalAyahs = 0,
    this.totalWords = 0,
    this.errorMessage,
    this.isRecording = false,
  });

  RecitationState copyWith({
    RecitationStatus? status,
    String? sessionId,
    int? surahId,
    String? surahName,
    int? currentAyah,
    int? currentWordIndex,
    List<RecitationWord>? words,
    int? totalAyahs,
    int? totalWords,
    String? errorMessage,
    bool? isRecording,
  }) {
    return RecitationState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      surahId: surahId ?? this.surahId,
      surahName: surahName ?? this.surahName,
      currentAyah: currentAyah ?? this.currentAyah,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      words: words ?? this.words,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      totalWords: totalWords ?? this.totalWords,
      errorMessage: errorMessage,
      isRecording: isRecording ?? this.isRecording,
    );
  }

  /// Calculate accuracy percentage (over processed words only)
  double get accuracy {
    final processed = words.where((w) => w.status != 'pending').length;
    if (processed == 0) return 0.0;
    final correctCount = words.where((w) => w.status == 'correct').length;
    return (correctCount / processed) * 100;
  }

  /// Count of correct words
  int get correctWordsCount => words.where((w) => w.status == 'correct').length;

  /// Count of mistakes (includes skipped words — Tarteel-style)
  int get mistakesCount =>
      words.where((w) => w.status == 'mistake' || w.status == 'skipped').length;

  @override
  List<Object?> get props => [
    status,
    sessionId,
    surahId,
    surahName,
    currentAyah,
    currentWordIndex,
    words,
    totalAyahs,
    totalWords,
    errorMessage,
    isRecording,
  ];
}
