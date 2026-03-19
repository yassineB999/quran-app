import 'package:equatable/equatable.dart';
import 'package:quranapp/features/audio/domain/entities/reciter.dart';

/// Base class for audio player events
abstract class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load audio for a surah
class LoadAudioEvent extends AudioPlayerEvent {
  final int surahId;
  final int? reciterId;

  const LoadAudioEvent({required this.surahId, this.reciterId});

  @override
  List<Object?> get props => [surahId, reciterId];
}

/// Event to play the audio
class PlayEvent extends AudioPlayerEvent {
  const PlayEvent();
}

/// Event to pause the audio
class PauseEvent extends AudioPlayerEvent {
  const PauseEvent();
}

/// Event to stop the audio (e.g. on exit)
class StopEvent extends AudioPlayerEvent {
  const StopEvent();
}

class PlayPlaylistEvent extends AudioPlayerEvent {
  final List<String> urls;
  const PlayPlaylistEvent(this.urls);
  @override
  List<Object> get props => [urls];
}

/// Event to seek to a position
class SeekEvent extends AudioPlayerEvent {
  final Duration position;

  const SeekEvent(this.position);

  @override
  List<Object?> get props => [position];
}

/// Event to change playback speed
class ChangeSpeedEvent extends AudioPlayerEvent {
  final double speed;

  const ChangeSpeedEvent(this.speed);

  @override
  List<Object?> get props => [speed];
}

/// Event to toggle repeat mode
class ToggleRepeatEvent extends AudioPlayerEvent {
  const ToggleRepeatEvent();
}

/// Event to change reciter
class ChangeReciterEvent extends AudioPlayerEvent {
  final Reciter reciter;
  final int surahId;

  const ChangeReciterEvent({required this.reciter, required this.surahId});

  @override
  List<Object?> get props => [reciter, surahId];
}

/// Event to load available reciters
class LoadRecitersEvent extends AudioPlayerEvent {
  const LoadRecitersEvent();
}

/// Event to skip to next surah
class NextSurahEvent extends AudioPlayerEvent {
  const NextSurahEvent();
}

/// Event to go to previous surah
class PreviousSurahEvent extends AudioPlayerEvent {
  const PreviousSurahEvent();
}

/// Event when position updates (internal)
class PositionUpdatedEvent extends AudioPlayerEvent {
  final Duration position;
  final Duration? duration;

  const PositionUpdatedEvent({required this.position, this.duration});

  @override
  List<Object?> get props => [position, duration];
}

/// Event when audio completes (internal)
class AudioCompletedEvent extends AudioPlayerEvent {
  const AudioCompletedEvent();
}

/// Event when playlist index updates
class CurrentIndexUpdatedEvent extends AudioPlayerEvent {
  final int? index;

  const CurrentIndexUpdatedEvent(this.index);

  @override
  List<Object?> get props => [index];
}
