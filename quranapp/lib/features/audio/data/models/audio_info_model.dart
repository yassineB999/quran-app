import 'package:quranapp/features/audio/domain/entities/audio_info.dart';

/// Model for AudioInfo with JSON serialization
class AudioInfoModel extends AudioInfo {
  const AudioInfoModel({
    required super.reciterId,
    required super.surahId,
    required super.audioUrl,
  });

  factory AudioInfoModel.fromJson(Map<String, dynamic> json) {
    return AudioInfoModel(
      reciterId: json['reciter_id'] ?? 0,
      surahId: int.tryParse(json['surah_id'].toString()) ?? 0,
      audioUrl: json['audio_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reciter_id': reciterId,
      'surah_id': surahId,
      'audio_url': audioUrl,
    };
  }
}
