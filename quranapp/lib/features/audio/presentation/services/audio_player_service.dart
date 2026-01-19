import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// Service that wraps just_audio for playing Quran audio
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  AudioPlayer get player => _player;

  /// Stream of current playback position
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of buffered position
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  /// Stream of total duration
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream of player state
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream of playing status
  Stream<bool> get playingStream => _player.playingStream;

  /// Current position
  Duration get position => _player.position;

  /// Current duration
  Duration? get duration => _player.duration;

  /// Whether currently playing
  bool get isPlaying => _player.playing;

  /// Check if audio is at the end
  bool get isCompleted => _player.processingState == ProcessingState.completed;

  /// Initialize the audio session
  Future<void> init() async {
    if (_isInitialized) return;

    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: true,
      ),
    );

    _isInitialized = true;
  }

  /// Load audio from URL
  Future<void> loadAudio(String url) async {
    await init();
    await _player.setUrl(url);
  }

  /// Load audio playlist
  Future<void> playPlaylist(List<String> urls) async {
    await init();
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: urls.map((url) => AudioSource.uri(Uri.parse(url))).toList(),
    );
    await _player.setAudioSource(playlist);
    await _player.play();
  }

  /// Load audio from local file
  Future<void> loadLocalAudio(String filePath) async {
    await init();
    await _player.setFilePath(filePath);
  }

  /// Play the audio (seeks to start if at end)
  Future<void> play() async {
    // If audio completed, seek to beginning first
    if (isCompleted || position >= (duration ?? Duration.zero)) {
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }

  /// Pause the audio
  Future<void> pause() async {
    await _player.pause();
  }

  /// Stop the audio and reset position
  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  /// Seek to a position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Get current speed
  double get speed => _player.speed;

  /// Set loop mode
  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  /// Get current loop mode
  LoopMode get loopMode => _player.loopMode;

  /// Dispose the player
  Future<void> dispose() async {
    await _player.dispose();
  }
}
