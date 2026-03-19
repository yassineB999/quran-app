import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
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
  final Failure? failure;
  final String status;
  final int? currentIndex;

  const AudioPlayerState({
    this.surahId = 1,
    this.currentReciter,
    this.availableReciters = const [],
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.isRepeating = false,
    this.failure,
    this.status = 'initial',
    this.currentIndex,
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
    failure,
    status,
    currentIndex,
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
    super.currentIndex,
  }) : super(status: 'playing');

  AudioPlayerPlaying copyWith({
    int? surahId,
    Reciter? currentReciter,
    List<Reciter>? availableReciters,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? isRepeating,
    int? currentIndex,
  }) {
    return AudioPlayerPlaying(
      surahId: surahId ?? this.surahId,
      currentReciter: currentReciter ?? this.currentReciter,
      availableReciters: availableReciters ?? this.availableReciters,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      isRepeating: isRepeating ?? this.isRepeating,
      currentIndex: currentIndex ?? this.currentIndex,
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
    super.currentIndex,
  }) : super(status: 'paused');

  AudioPlayerPaused copyWith({
    int? surahId,
    Reciter? currentReciter,
    List<Reciter>? availableReciters,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? isRepeating,
    int? currentIndex,
  }) {
    return AudioPlayerPaused(
      surahId: surahId ?? this.surahId,
      currentReciter: currentReciter ?? this.currentReciter,
      availableReciters: availableReciters ?? this.availableReciters,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      isRepeating: isRepeating ?? this.isRepeating,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

/// Error state
class AudioPlayerError extends AudioPlayerState {
  const AudioPlayerError({
    required Failure failure,
    super.surahId,
    super.currentReciter,
    super.availableReciters,
  }) : super(status: 'error', failure: failure);
}
