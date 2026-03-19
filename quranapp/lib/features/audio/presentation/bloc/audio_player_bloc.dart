import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/audio/domain/entities/reciter.dart';
import 'package:quranapp/features/audio/domain/usecases/get_audio_url.dart';
import 'package:quranapp/features/audio/domain/usecases/get_reciters.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_event.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_state.dart';
import 'package:quranapp/features/audio/presentation/services/audio_player_service.dart';

class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  final AudioPlayerService audioService;
  final GetReciters getReciters;
  final GetAudioUrl getAudioUrl;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;

  List<Reciter> _reciters = [];
  Reciter? _currentReciter;
  int _currentSurahId = 1;
  Duration _duration = Duration.zero;
  bool _isAudioCompleted = false;

  AudioPlayerBloc({
    required this.audioService,
    required this.getReciters,
    required this.getAudioUrl,
  }) : super(const AudioPlayerInitial()) {
    on<LoadRecitersEvent>(_onLoadReciters);
    on<LoadAudioEvent>(_onLoadAudio);
    on<PlayEvent>(_onPlay);
    on<PauseEvent>(_onPause);
    on<StopEvent>(_onStop);
    on<SeekEvent>(_onSeek);
    on<ChangeSpeedEvent>(_onChangeSpeed);
    on<ToggleRepeatEvent>(_onToggleRepeat);
    on<ChangeReciterEvent>(_onChangeReciter);
    on<NextSurahEvent>(_onNextSurah);
    on<PreviousSurahEvent>(_onPreviousSurah);
    on<PositionUpdatedEvent>(_onPositionUpdated);
    on<AudioCompletedEvent>(_onAudioCompleted);
    on<PlayPlaylistEvent>(_onPlayPlaylist);
    on<CurrentIndexUpdatedEvent>(_onCurrentIndexUpdated);

    _setupStreams();
  }

  void _setupStreams() {
    _positionSubscription = audioService.positionStream.listen((position) {
      if (!_isAudioCompleted) {
        add(PositionUpdatedEvent(position: position, duration: _duration));
      }
    });

    _durationSubscription = audioService.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
      }
    });

    _playerStateSubscription = audioService.playerStateStream.listen((
      playerState,
    ) {
      if (playerState.processingState == ProcessingState.completed) {
        _isAudioCompleted = true;
        add(const AudioCompletedEvent());
      }
    });

    _currentIndexSubscription = audioService.currentIndexStream.listen((index) {
      add(CurrentIndexUpdatedEvent(index));
    });
  }

  void _onAudioCompleted(
    AudioCompletedEvent event,
    Emitter<AudioPlayerState> emit,
  ) {
    if (state is AudioPlayerPlaying) {
      final s = state as AudioPlayerPlaying;
      emit(
        AudioPlayerPaused(
          surahId: s.surahId,
          currentReciter: s.currentReciter,
          availableReciters: s.availableReciters,
          position: s.duration, // Set to end
          duration: s.duration,
          speed: s.speed,
          isRepeating: s.isRepeating,
          currentIndex: s.currentIndex,
        ),
      );
    }
  }

  Future<void> _onLoadReciters(
    LoadRecitersEvent event,
    Emitter<AudioPlayerState> emit,
  ) async {
    final result = await getReciters(NoParams());

    result.fold(
      (failure) =>
          emit(AudioPlayerError(failure: failure, surahId: _currentSurahId)),
      (reciters) {
        _reciters = reciters;
        if (reciters.isNotEmpty && _currentReciter == null) {
          _currentReciter = reciters.first;
        }
      },
    );
  }

  Future<void> _onLoadAudio(
    LoadAudioEvent event,
    Emitter<AudioPlayerState> emit,
  ) async {
    _currentSurahId = event.surahId;
    _isAudioCompleted = false;

    // Ensure we are stopped before loading new audio to prevent auto-play artifacts
    await audioService.stop();

    emit(
      AudioPlayerLoading(
        surahId: _currentSurahId,
        currentReciter: _currentReciter,
        availableReciters: _reciters,
      ),
    );

    // Load reciters if not loaded
    if (_reciters.isEmpty) {
      final recitersResult = await getReciters(NoParams());
      recitersResult.fold((failure) => null, (reciters) {
        _reciters = reciters;
        if (reciters.isNotEmpty && _currentReciter == null) {
          _currentReciter = reciters.first;
        }
      });
    }

    // Use provided reciterId or default
    final reciterId = event.reciterId ?? _currentReciter?.id ?? 1;

    final result = await getAudioUrl(
      GetAudioUrlParams(reciterId: reciterId, surahId: event.surahId),
    );

    await result.fold(
      (failure) async {
        emit(
          AudioPlayerError(
            failure: failure,
            surahId: _currentSurahId,
            currentReciter: _currentReciter,
            availableReciters: _reciters,
          ),
        );
      },
      (audioInfo) async {
        try {
          await audioService.loadAudio(audioInfo.audioUrl);
          _duration = audioService.duration ?? Duration.zero;

          final isPlayingNow = audioService.isPlaying;
          if (isPlayingNow) {
            emit(
              AudioPlayerPlaying(
                surahId: _currentSurahId,
                currentReciter: _currentReciter,
                availableReciters: _reciters,
                position: audioService.position,
                duration: _duration,
                speed: audioService.speed,
                isRepeating: audioService.loopMode != LoopMode.off,
                currentIndex: audioService.currentIndex,
              ),
            );
          } else {
            emit(
              AudioPlayerPaused(
                surahId: _currentSurahId,
                currentReciter: _currentReciter,
                availableReciters: _reciters,
                position: Duration.zero,
                duration: _duration,
                speed: audioService.speed,
                isRepeating: audioService.loopMode != LoopMode.off,
                currentIndex: audioService.currentIndex,
              ),
            );
          }
        } catch (e) {
          emit(
            AudioPlayerError(
              failure: CacheFailure('Failed to load audio: $e'),
              surahId: _currentSurahId,
              currentReciter: _currentReciter,
              availableReciters: _reciters,
            ),
          );
        }
      },
    );
  }

  Future<void> _onPlay(PlayEvent event, Emitter<AudioPlayerState> emit) async {
    _isAudioCompleted = false;
    final current = state;
    if (current is AudioPlayerPlaying) {
      await audioService.play();
      return;
    }
    final surahId = current.surahId;
    final reciter = current.currentReciter ?? _currentReciter;
    final reciters = current.availableReciters.isNotEmpty
        ? current.availableReciters
        : _reciters;
    final duration = current.duration != Duration.zero
        ? current.duration
        : _duration;
    final speed = current.speed;
    final isRepeating = current.isRepeating;
    emit(
      AudioPlayerPlaying(
        surahId: surahId,
        currentReciter: reciter,
        availableReciters: reciters,
        position: audioService.position,
        duration: duration,
        speed: speed,
        isRepeating: isRepeating,
        currentIndex: audioService.currentIndex,
      ),
    );
    await audioService.play();
  }

  Future<void> _onPause(
    PauseEvent event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await audioService.pause();
    if (state is AudioPlayerPlaying) {
      final s = state as AudioPlayerPlaying;
      emit(
        AudioPlayerPaused(
          surahId: s.surahId,
          currentReciter: s.currentReciter,
          availableReciters: s.availableReciters,
          position: audioService.position,
          duration: s.duration,
          speed: s.speed,
          isRepeating: s.isRepeating,
          currentIndex: s.currentIndex,
        ),
      );
    }
  }

  Future<void> _onStop(StopEvent event, Emitter<AudioPlayerState> emit) async {
    await audioService.stop();
    // When stopped, we are essentially paused at 0
    if (state is AudioPlayerPlaying || state is AudioPlayerPaused) {
      emit(
        AudioPlayerPaused(
          surahId: _currentSurahId,
          currentReciter: _currentReciter,
          availableReciters: _reciters,
          position: Duration.zero,
          duration: _duration,
          speed: audioService.speed,
          isRepeating: audioService.loopMode != LoopMode.off,
          currentIndex: audioService.currentIndex,
        ),
      );
    }
  }

  Future<void> _onPlayPlaylist(
    PlayPlaylistEvent event,
    Emitter<AudioPlayerState> emit,
  ) async {
    try {
      await audioService.stop();
      emit(
        AudioPlayerLoading(
          surahId: 0,
          currentReciter: _currentReciter,
          availableReciters: _reciters,
        ),
      );

      await audioService.playPlaylist(event.urls);

      emit(
        AudioPlayerPlaying(
          surahId: 0,
          currentReciter: _currentReciter,
          availableReciters: _reciters,
          position: Duration.zero,
          duration: Duration.zero,
          speed: audioService.speed,
          isRepeating: audioService.loopMode != LoopMode.off,
          currentIndex: audioService.currentIndex,
        ),
      );
    } catch (e) {
      emit(
        AudioPlayerError(
          failure: CacheFailure('Failed to play playlist: $e'),
          surahId: _currentSurahId,
          currentReciter: _currentReciter,
          availableReciters: _reciters,
        ),
      );
    }
  }

  Future<void> _onSeek(SeekEvent event, Emitter<AudioPlayerState> emit) async {
    _isAudioCompleted = false;
    await audioService.seek(event.position);

    // Update position in current state
    if (state is AudioPlayerPlaying) {
      emit((state as AudioPlayerPlaying).copyWith(position: event.position));
    } else if (state is AudioPlayerPaused) {
      emit((state as AudioPlayerPaused).copyWith(position: event.position));
    }
  }

  Future<void> _onChangeSpeed(
    ChangeSpeedEvent event,
    Emitter<AudioPlayerState> emit,
  ) async {
    await audioService.setSpeed(event.speed);
    if (state is AudioPlayerPlaying) {
      emit((state as AudioPlayerPlaying).copyWith(speed: event.speed));
    } else if (state is AudioPlayerPaused) {
      emit((state as AudioPlayerPaused).copyWith(speed: event.speed));
    }
  }

  Future<void> _onToggleRepeat(
    ToggleRepeatEvent event,
    Emitter<AudioPlayerState> emit,
  ) async {
    final newMode = audioService.loopMode == LoopMode.off
        ? LoopMode.one
        : LoopMode.off;
    await audioService.setLoopMode(newMode);
    final isRepeating = newMode != LoopMode.off;

    if (state is AudioPlayerPlaying) {
      emit((state as AudioPlayerPlaying).copyWith(isRepeating: isRepeating));
    } else if (state is AudioPlayerPaused) {
      emit((state as AudioPlayerPaused).copyWith(isRepeating: isRepeating));
    }
  }

  Future<void> _onChangeReciter(
    ChangeReciterEvent event,
    Emitter<AudioPlayerState> emit,
  ) async {
    _currentReciter = event.reciter;
    add(LoadAudioEvent(surahId: event.surahId, reciterId: event.reciter.id));
  }

  Future<void> _onNextSurah(
    NextSurahEvent event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (_currentSurahId < 114) {
      add(LoadAudioEvent(surahId: _currentSurahId + 1));
    }
  }

  Future<void> _onPreviousSurah(
    PreviousSurahEvent event,
    Emitter<AudioPlayerState> emit,
  ) async {
    if (_currentSurahId > 1) {
      add(LoadAudioEvent(surahId: _currentSurahId - 1));
    }
  }

  void _onPositionUpdated(
    PositionUpdatedEvent event,
    Emitter<AudioPlayerState> emit,
  ) {
    if (state is AudioPlayerPlaying && !_isAudioCompleted) {
      emit(
        (state as AudioPlayerPlaying).copyWith(
          position: event.position,
          duration: event.duration ?? state.duration,
        ),
      );
    }
  }

  void _onCurrentIndexUpdated(
    CurrentIndexUpdatedEvent event,
    Emitter<AudioPlayerState> emit,
  ) {
    if (state is AudioPlayerPlaying) {
      emit((state as AudioPlayerPlaying).copyWith(currentIndex: event.index));
    } else if (state is AudioPlayerPaused) {
      emit((state as AudioPlayerPaused).copyWith(currentIndex: event.index));
    }
  }

  @override
  Future<void> close() async {
    await audioService.stop();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _playerStateSubscription?.cancel();
    await _currentIndexSubscription?.cancel();
    return super.close();
  }
}
