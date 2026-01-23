import 'package:equatable/equatable.dart';
import 'package:quranapp/features/audio/domain/entities/reciter.dart';

/// Base class for audio player states
abstract class AudioPlayerState extends Equatable {
  final int surahId;
  final Reciter? currentReciter;
  final List<Reciter> availableReciters;
  final Duration position;
  final Duration duration;
  final double speed;
  final bool isRepeating;
  final String? errorMessage;
  final String status;

  const AudioPlayerState({
    this.surahId = 1,
    this.currentReciter,
    this.availableReciters = const [],
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.isRepeating = false,
    this.errorMessage,
    this.status = 'initial',
  });

  @override
  List<Object?> get props => [
    surahId,
    currentReciter,
    availableReciters,
    position,
    duration,
    speed,
    isRepeating,
    errorMessage,
    status,
  ];
}

/// Initial state
class AudioPlayerInitial extends AudioPlayerState {
  const AudioPlayerInitial() : super(status: 'initial');
}

/// Loading state
class AudioPlayerLoading extends AudioPlayerState {
  const AudioPlayerLoading({
    super.surahId,
    super.currentReciter,
    super.availableReciters,
  }) : super(status: 'loading');
}

/// Playing state
class AudioPlayerPlaying extends AudioPlayerState {
  const AudioPlayerPlaying({
    required super.surahId,
    required super.currentReciter,
    required super.availableReciters,
    required super.position,
    required super.duration,
    required super.speed,
    required super.isRepeating,
  }) : super(status: 'playing');

  AudioPlayerPlaying copyWith({
    int? surahId,
    Reciter? currentReciter,
    List<Reciter>? availableReciters,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? isRepeating,
  }) {
    return AudioPlayerPlaying(
      surahId: surahId ?? this.surahId,
      currentReciter: currentReciter ?? this.currentReciter,
      availableReciters: availableReciters ?? this.availableReciters,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      isRepeating: isRepeating ?? this.isRepeating,
    );
  }
}

/// Paused state
class AudioPlayerPaused extends AudioPlayerState {
  const AudioPlayerPaused({
    required super.surahId,
    required super.currentReciter,
    required super.availableReciters,
    required super.position,
    required super.duration,
    required super.speed,
    required super.isRepeating,
  }) : super(status: 'paused');

  AudioPlayerPaused copyWith({
    int? surahId,
    Reciter? currentReciter,
    List<Reciter>? availableReciters,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? isRepeating,
  }) {
    return AudioPlayerPaused(
      surahId: surahId ?? this.surahId,
      currentReciter: currentReciter ?? this.currentReciter,
      availableReciters: availableReciters ?? this.availableReciters,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      isRepeating: isRepeating ?? this.isRepeating,
    );
  }
}

/// Error state
class AudioPlayerError extends AudioPlayerState {
  const AudioPlayerError({
    required super.errorMessage,
    super.surahId,
    super.currentReciter,
    super.availableReciters,
  }) : super(status: 'error');
}
