import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/features/audio/data/datasources/websocket_data_source.dart';
import 'package:quranapp/features/quran/domain/entities/recitation_word.dart';
import 'package:quranapp/features/quran/domain/usecases/get_surah_detail.dart';
import 'package:quranapp/features/quran/presentation/bloc/recitation/recitation_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/recitation/recitation_state.dart';
import 'package:record/record.dart';

class RecitationBloc extends Bloc<RecitationEvent, RecitationState> {
  final WebSocketDataSource webSocketDataSource;
  final AudioRecorder audioRecorder;
  final GetSurahDetail getSurahDetail;

  StreamSubscription? _wsSubscription;
  StreamSubscription? _recordingSubscription;

  RecitationBloc({
    required this.webSocketDataSource,
    required this.audioRecorder,
    required this.getSurahDetail,
  }) : super(const RecitationState()) {
    on<InitializeRecitationSession>(_onInitialize);
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<PauseRecitation>(_onPauseRecitation);
    on<ResumeRecitation>(_onResumeRecitation);
    on<SendAudioChunk>(_onSendAudioChunk);
    on<ReceivedWordUpdate>(_onReceivedWordUpdate);
    on<SessionReady>(_onSessionReady);
    on<RecitationError>(_onRecitationError);
    on<ResetRecitation>(_onResetRecitation);
    on<WebSocketDisconnected>(_onWebSocketDisconnected);
  }

  Future<void> _onInitialize(
    InitializeRecitationSession event,
    Emitter<RecitationState> emit,
  ) async {
    try {
      emit(
        state.copyWith(
          status: RecitationStatus.connecting,
          surahId: event.surahId,
          surahName: event.surahName,
          errorMessage: null,
        ),
      );

      // 1. Fetch Surah details to pre-populate words
      final failureOrSurah = await getSurahDetail(
        GetSurahDetailParams(id: event.surahId),
      );

      failureOrSurah.fold(
        (failure) {
          emit(
            state.copyWith(
              status: RecitationStatus.error,
              errorMessage: 'Failed to load surah: ${failure.toString()}',
            ),
          );
        },
        (surah) {
          // Flatten verses into RecitationWord list
          final allWords = <RecitationWord>[];
          for (final verse in surah.verses) {
            final words = verse.text.split(' ');
            for (var i = 0; i < words.length; i++) {
              if (words[i].trim().isEmpty) continue;
              allWords.add(
                RecitationWord.pending(
                  ayah: verse.numberInSurah,
                  wordIndex: i,
                  expected: words[i],
                ),
              );
            }
          }

          emit(
            state.copyWith(
              words: allWords,
              totalAyahs: surah.versesCount,
              totalWords: allWords.length,
            ),
          );
        },
      );

      // If we failed to load surah, stop here
      if (state.status == RecitationStatus.error) return;

      // 2. Connect to WebSocket with surah ID and word data.
      // Sending words ensures the AI service uses the same Warsh text
      // source as the UI, preventing the text source mismatch problem.
      final wordsForWs = state.words
          .map(
            (w) => <String, dynamic>{
              'ayah': w.ayah,
              'word_index': w.wordIndex,
              'text': w.expected,
            },
          )
          .toList();
      await webSocketDataSource.connect(
        surahId: event.surahId,
        words: wordsForWs,
      );

      // Listen to WebSocket messages
      _wsSubscription = webSocketDataSource.responseStream.listen(
        (message) {
          final type = message['type'] as String?;

          if (type == 'session_ready') {
            add(
              SessionReady(
                sessionId: message['session_id'] as String,
                // totalAyahs and totalWords are now pre-loaded
              ),
            );
          } else if (type == 'recitation_update') {
            add(ReceivedWordUpdate(message));
          } else if (type == 'error') {
            add(RecitationError(message['message'] as String));
          }
        },
        onError: (error) {
          add(RecitationError(error.toString()));
        },
        onDone: () {
          add(const WebSocketDisconnected());
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RecitationStatus.error,
          errorMessage: 'Failed to connect: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSessionReady(
    SessionReady event,
    Emitter<RecitationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RecitationStatus.ready,
        sessionId: event.sessionId,
        // totalAyahs and totalWords are already set during initialization
        // words: [], // Words are now pre-populated
      ),
    );
  }

  Future<void> _onStartRecording(
    StartRecording event,
    Emitter<RecitationState> emit,
  ) async {
    try {
      if (!await audioRecorder.hasPermission()) {
        emit(
          state.copyWith(
            status: RecitationStatus.error,
            errorMessage: 'Microphone permission denied',
          ),
        );
        return;
      }

      // Start recording with PCM 16-bit, 16kHz, mono
      // Using startStream instead for continuous streaming
      final stream = await audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      emit(
        state.copyWith(status: RecitationStatus.reciting, isRecording: true),
      );

      // Stream audio chunks to WebSocket
      _recordingSubscription = stream.listen((chunk) {
        add(SendAudioChunk(chunk));
      });
    } catch (e) {
      emit(
        state.copyWith(
          status: RecitationStatus.error,
          errorMessage: 'Failed to start recording: ${e.toString()}',
          isRecording: false,
        ),
      );
    }
  }

  Future<void> _onStopRecording(
    StopRecording event,
    Emitter<RecitationState> emit,
  ) async {
    await _stopRecordingInternal();
    emit(
      state.copyWith(status: RecitationStatus.completed, isRecording: false),
    );
  }

  Future<void> _onPauseRecitation(
    PauseRecitation event,
    Emitter<RecitationState> emit,
  ) async {
    await _stopRecordingInternal();
    emit(state.copyWith(status: RecitationStatus.paused, isRecording: false));
  }

  Future<void> _onResumeRecitation(
    ResumeRecitation event,
    Emitter<RecitationState> emit,
  ) async {
    add(const StartRecording());
  }

  Future<void> _onSendAudioChunk(
    SendAudioChunk event,
    Emitter<RecitationState> emit,
  ) async {
    try {
      // Convert List<int> to Uint8List
      final audioData = Uint8List.fromList(event.audioData);
      webSocketDataSource.sendAudioChunk(audioData);
    } catch (e) {
      emit(
        state.copyWith(
          status: RecitationStatus.error,
          errorMessage: 'Failed to send audio: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onReceivedWordUpdate(
    ReceivedWordUpdate event,
    Emitter<RecitationState> emit,
  ) async {
    try {
      final update = event.update;
      final wordsList = update['words'] as List<dynamic>?;

      if (wordsList == null) return;

      final updateWords = wordsList
          .map((json) => RecitationWord.fromJson(json as Map<String, dynamic>))
          .toList();

      // Merge updates into existing words list
      final currentWords = List<RecitationWord>.from(state.words);

      for (final update in updateWords) {
        // Find matching word
        final index = currentWords.indexWhere(
          (w) => w.ayah == update.ayah && w.wordIndex == update.wordIndex,
        );

        if (index != -1) {
          currentWords[index] = update;
        } else {
          // Handle case where server sends words not in our list (e.g. alignment mismatch or extra word)
          // For now, we can append or ignore. If strict, ignore.
        }
      }

      emit(
        state.copyWith(
          currentAyah: update['current_ayah'] as int,
          currentWordIndex: update['current_word_index'] as int,
          words: currentWords,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RecitationStatus.error,
          errorMessage: 'Failed to process update: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onRecitationError(
    RecitationError event,
    Emitter<RecitationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: RecitationStatus.error,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onResetRecitation(
    ResetRecitation event,
    Emitter<RecitationState> emit,
  ) async {
    await _cleanup();
    emit(const RecitationState());
  }

  Future<void> _onWebSocketDisconnected(
    WebSocketDisconnected event,
    Emitter<RecitationState> emit,
  ) async {
    await _stopRecordingInternal();
    emit(
      state.copyWith(
        status: RecitationStatus.error,
        errorMessage: 'Connection lost',
        isRecording: false,
      ),
    );
  }

  Future<void> _stopRecordingInternal() async {
    await _recordingSubscription?.cancel();
    _recordingSubscription = null;

    if (await audioRecorder.isRecording()) {
      await audioRecorder.stop();
    }
  }

  Future<void> _cleanup() async {
    await _stopRecordingInternal();
    await _wsSubscription?.cancel();
    _wsSubscription = null;
    await webSocketDataSource.disconnect();
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}
