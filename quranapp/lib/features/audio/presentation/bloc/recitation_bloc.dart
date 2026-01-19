import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart'; // Contains Verse
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';

// Events
abstract class RecitationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadRecitationSurah extends RecitationEvent {
  final int surahId;
  LoadRecitationSurah(this.surahId);
}

class StartRecitationSession extends RecitationEvent {}

class StopRecitationSession extends RecitationEvent {}

class ProcessAudioChunk extends RecitationEvent {
  final List<int> data;
  ProcessAudioChunk(this.data);
}

class ServerMessageReceived extends RecitationEvent {
  final dynamic message;
  ServerMessageReceived(this.message);
}

// States
enum VerseStatus { pending, reciting, correct, mistake }

enum ConnectionStatus { disconnected, connecting, connected, failed }

class VerseFeedback {
  final VerseStatus status;
  final Set<int> correctWords;
  final Set<int> mistakeWords;
  final List<String> feedbackMessages;

  const VerseFeedback({
    this.status = VerseStatus.pending,
    this.correctWords = const {},
    this.mistakeWords = const {},
    this.feedbackMessages = const [],
  });

  VerseFeedback copyWith({
    VerseStatus? status,
    Set<int>? correctWords,
    Set<int>? mistakeWords,
    List<String>? feedbackMessages,
  }) {
    return VerseFeedback(
      status: status ?? this.status,
      correctWords: correctWords ?? this.correctWords,
      mistakeWords: mistakeWords ?? this.mistakeWords,
      feedbackMessages: feedbackMessages ?? this.feedbackMessages,
    );
  }
}

class RecitationState extends Equatable {
  final Surah? surah;
  final List<Verse> ayahs; // Renamed to ayahs for consistency but type is Verse
  final bool isLoading;
  final ConnectionStatus connectionStatus;
  final int currentVerseIndex; // 1-based usually, or 0-based list index
  final Map<int, VerseFeedback> verseFeedback; // Key: Verse Number
  final String? errorMessage;
  final bool isRecording;

  const RecitationState({
    this.surah,
    this.ayahs = const [],
    this.isLoading = false,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.currentVerseIndex = 0,
    this.verseFeedback = const {},
    this.errorMessage,
    this.isRecording = false,
  });

  RecitationState copyWith({
    Surah? surah,
    List<Verse>? ayahs,
    bool? isLoading,
    ConnectionStatus? connectionStatus,
    int? currentVerseIndex,
    Map<int, VerseFeedback>? verseFeedback,
    String? errorMessage,
    bool? isRecording,
  }) {
    return RecitationState(
      surah: surah ?? this.surah,
      ayahs: ayahs ?? this.ayahs,
      isLoading: isLoading ?? this.isLoading,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      currentVerseIndex: currentVerseIndex ?? this.currentVerseIndex,
      verseFeedback: verseFeedback ?? this.verseFeedback,
      errorMessage: errorMessage,
      isRecording: isRecording ?? this.isRecording,
    );
  }

  @override
  List<Object?> get props => [
    surah,
    ayahs,
    isLoading,
    connectionStatus,
    currentVerseIndex,
    verseFeedback,
    errorMessage,
    isRecording,
  ];
}

// BLoC
class RecitationBloc extends Bloc<RecitationEvent, RecitationState> {
  final QuranRepository quranRepository;
  WebSocketChannel? _channel;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription? _recordSub;

  RecitationBloc({required this.quranRepository})
    : super(const RecitationState()) {
    on<LoadRecitationSurah>(_onLoadSurah);
    on<StartRecitationSession>(_onStartSession);
    on<StopRecitationSession>(_onStopSession);
    on<ServerMessageReceived>(_onServerMessage);
  }

  Future<void> _onLoadSurah(
    LoadRecitationSurah event,
    Emitter<RecitationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await quranRepository.getSurah(event.surahId);
    result.fold(
      (failure) => emit(
        state.copyWith(isLoading: false, errorMessage: "Failed to load Surah"),
      ),
      (surah) {
        // Init feedback map
        final feedback = <int, VerseFeedback>{};
        for (var verse in surah.verses) {
          feedback[verse.number] = const VerseFeedback();
        }
        emit(
          state.copyWith(
            isLoading: false,
            surah: surah,
            ayahs: surah.verses,
            verseFeedback: feedback,
            currentVerseIndex: 0, // Start at first ayah
          ),
        );
      },
    );
  }

  Future<void> _onStartSession(
    StartRecitationSession event,
    Emitter<RecitationState> emit,
  ) async {
    if (state.surah == null) return;

    emit(
      state.copyWith(
        connectionStatus: ConnectionStatus.connecting,
        errorMessage: null,
      ),
    );

    try {
      // Connect to Proxy
      // Note: This feature is being migrated to REST API check (RecitationCheckCubit)
      // _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.1.6:6001'));
      // await _channel!.ready;

      // Start Stream Listener
      _channel!.stream.listen(
        (msg) {
          // debugPrint("🔥 [RecitationBloc] Raw Message: $msg"); // TOO NOISY if binary
          add(ServerMessageReceived(msg));
        },
        onError: (e) =>
            add(StopRecitationSession()), // Handle error properly in real app
        onDone: () => add(StopRecitationSession()),
      );

      emit(state.copyWith(connectionStatus: ConnectionStatus.connected));

      // Send Start Config
      // Start from current verse
      final currentVerse = state.ayahs[state.currentVerseIndex];
      // Note: API expects chapter_index, verse_index.
      // Qurani indices might be 1-based? Usually yes.

      final config = {
        "method": "StartTilawaSession",
        "chapter_index": state.surah!.number,
        "verse_index": currentVerse
            .number, // Or index in surah? Usually Verse Number (Global or local?) Qurani uses local usually? Check docs. Local.
        "word_index": 1,
        "hafz_level": 1,
        "tajweed_level": 3,
        "audio_format": "pcm", // Explicit format
        "sample_rate": 16000, // Explicit rate
      };

      _channel!.sink.add(jsonEncode(config));

      // Start Recording
      if (await _audioRecorder.hasPermission()) {
        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        _recordSub = stream.listen((data) {
          if (state.connectionStatus == ConnectionStatus.connected) {
            _channel!.sink.add(data);
          }
        });

        emit(state.copyWith(isRecording: true)); // Mark as recording
      }
    } catch (e) {
      emit(
        state.copyWith(
          connectionStatus: ConnectionStatus.failed,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onStopSession(
    StopRecitationSession event,
    Emitter<RecitationState> emit,
  ) {
    _recordSub?.cancel();
    _audioRecorder.stop();
    _channel?.sink.close();
    emit(
      state.copyWith(
        isRecording: false,
        connectionStatus: ConnectionStatus.disconnected,
      ),
    );
  }

  void _onServerMessage(
    ServerMessageReceived event,
    Emitter<RecitationState> emit,
  ) {
    // Parse JSON
    if (event.message is String) {
      try {
        final data = jsonDecode(event.message);
        debugPrint("📩 [RecitationBloc] Server Event: ${data['event']}");

        if (data['event'] == 'check_tilawa') {
          debugPrint("📊 [RecitationBloc] Processing check_tilawa: $data");
          _processFeedback(data, emit);
        } else if (data['event'] == 'start_tilawa_session') {
          debugPrint("✅ [RecitationBloc] Session Started Confirmed by AI");
        }
      } catch (e) {
        debugPrint("❌ [RecitationBloc] JSON Parse Error: $e");
      }
    }
  }

  void _processFeedback(
    Map<String, dynamic> data,
    Emitter<RecitationState> emit,
  ) {
    final verseIdx = data['verse_index'] as int; // This comes from AI

    // Update current verse logic
    // If AI detects we moved to next verse, update index
    // Find the index in our list that matches verseIdx
    // Assumption: verseIdx matches Ayah.number (relative to Surah)

    final existingFeedback =
        state.verseFeedback[verseIdx] ?? const VerseFeedback();

    final correctList = (data['correct_words'] as List?) ?? [];
    final mistakeList = (data['tajweed_mistakes'] as List?) ?? [];
    final skippedList = (data['skipped_words'] as List?) ?? [];

    final newCorrect = Set<int>.from(existingFeedback.correctWords);
    final newMistakes = Set<int>.from(existingFeedback.mistakeWords);

    for (var w in correctList) {
      newCorrect.add(w['word']);
    }
    for (var w in mistakeList) {
      newMistakes.add(w['word']);
    }
    // Skipped words are also mistakes? Or just missing.
    for (var w in skippedList) {
      newMistakes.add(w['word']);
    }

    VerseStatus status = VerseStatus.reciting;
    if (correctList.isNotEmpty && mistakeList.isEmpty && skippedList.isEmpty) {
      // If mostly correct? Logic to determine "Completed"
      // For now, if we have correct words, it's 'reciting'.
    }

    // Aggregate Feedback Messages
    List<String> messages = List.from(existingFeedback.feedbackMessages);
    for (var m in mistakeList) {
      messages.add("Word ${m['word']}: ${m['message']}");
    }

    final newFeedbackMap = Map<int, VerseFeedback>.from(state.verseFeedback);
    newFeedbackMap[verseIdx] = existingFeedback.copyWith(
      status: status,
      correctWords: newCorrect,
      mistakeWords: newMistakes,
      feedbackMessages: messages,
    );

    // Check if verse changed
    int newIndex = state.currentVerseIndex;
    if (state.ayahs.isNotEmpty) {
      final currentVerseNum = state.ayahs[state.currentVerseIndex].number;
      if (verseIdx > currentVerseNum) {
        // Find new index
        final idx = state.ayahs.indexWhere((v) => v.number == verseIdx);
        if (idx != -1) newIndex = idx;
      }
    }

    emit(
      state.copyWith(
        verseFeedback: newFeedbackMap,
        currentVerseIndex: newIndex,
      ),
    );
  }
}
