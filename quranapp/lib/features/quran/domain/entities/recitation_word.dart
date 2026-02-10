import 'package:equatable/equatable.dart';

/// Represents a single word in the recitation with its status
class RecitationWord extends Equatable {
  final int ayah;
  final int wordIndex;
  final String expected; // Display text with tashkeel
  final String status; // correct | mistake | skipped | pending | active
  final String? spoken; // What was actually spoken (normalized)
  final double score; // Fuzzy match score (0-100)

  const RecitationWord({
    required this.ayah,
    required this.wordIndex,
    required this.expected,
    required this.status,
    this.spoken,
    this.score = 0.0,
  });

  RecitationWord copyWith({
    int? ayah,
    int? wordIndex,
    String? expected,
    String? status,
    String? spoken,
    double? score,
  }) {
    return RecitationWord(
      ayah: ayah ?? this.ayah,
      wordIndex: wordIndex ?? this.wordIndex,
      expected: expected ?? this.expected,
      status: status ?? this.status,
      spoken: spoken ?? this.spoken,
      score: score ?? this.score,
    );
  }

  factory RecitationWord.pending({
    required int ayah,
    required int wordIndex,
    required String expected,
  }) {
    return RecitationWord(
      ayah: ayah,
      wordIndex: wordIndex,
      expected: expected,
      status: 'pending',
    );
  }

  factory RecitationWord.fromJson(Map<String, dynamic> json) {
    return RecitationWord(
      ayah: json['ayah'] as int,
      wordIndex: json['word_index'] as int,
      expected: json['expected'] as String,
      status: json['status'] as String,
      spoken: json['spoken'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ayah': ayah,
      'word_index': wordIndex,
      'expected': expected,
      'status': status,
      'spoken': spoken,
      'score': score,
    };
  }

  @override
  List<Object?> get props => [ayah, wordIndex, expected, status, spoken, score];
}
