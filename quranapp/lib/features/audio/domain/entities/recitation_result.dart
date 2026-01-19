import 'package:equatable/equatable.dart';

class RecitationResult extends Equatable {
  final bool success;
  final String? transcription;
  final RecitationAnalysis? analysis;
  final String? message;

  const RecitationResult({
    required this.success,
    this.transcription,
    this.analysis,
    this.message,
  });

  @override
  List<Object?> get props => [success, transcription, analysis, message];
}

class RecitationAnalysis extends Equatable {
  final int surah;
  final int ayah;
  final String text;
  final double score;
  final bool isCorrect;

  const RecitationAnalysis({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.score,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [surah, ayah, text, score, isCorrect];
}
