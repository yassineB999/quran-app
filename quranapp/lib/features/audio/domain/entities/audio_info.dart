import 'package:equatable/equatable.dart';

/// Represents audio information for a surah
class AudioInfo extends Equatable {
  final int reciterId;
  final int surahId;
  final String audioUrl;

  const AudioInfo({
    required this.reciterId,
    required this.surahId,
    required this.audioUrl,
  });

  @override
  List<Object?> get props => [reciterId, surahId, audioUrl];
}
