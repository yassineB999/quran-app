import 'package:quranapp/features/audio/domain/entities/recitation_result.dart';

class RecitationResultModel extends RecitationResult {
  const RecitationResultModel({
    required super.success,
    super.transcription,
    super.analysis,
    super.message,
  });

  factory RecitationResultModel.fromJson(Map<String, dynamic> json) {
    return RecitationResultModel(
      success: json['success'] ?? false,
      transcription: json['transcription'],
      analysis: json['analysis'] != null
          ? RecitationAnalysisModel.fromJson(json['analysis'])
          : null,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transcription': transcription,
      'analysis': analysis != null
          ? (analysis as RecitationAnalysisModel).toJson()
          : null,
      'message': message,
    };
  }
}

class RecitationAnalysisModel extends RecitationAnalysis {
  const RecitationAnalysisModel({
    required super.surah,
    required super.ayah,
    required super.text,
    required super.score,
    required super.isCorrect,
  });

  factory RecitationAnalysisModel.fromJson(Map<String, dynamic> json) {
    return RecitationAnalysisModel(
      surah: json['surah'] ?? 0,
      ayah: json['ayah'] ?? 0,
      text: json['text'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      isCorrect: json['is_correct'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah': surah,
      'ayah': ayah,
      'text': text,
      'score': score,
      'is_correct': isCorrect,
    };
  }
}
