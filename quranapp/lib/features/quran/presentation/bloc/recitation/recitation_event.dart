import 'package:equatable/equatable.dart';

abstract class RecitationEvent extends Equatable {
  const RecitationEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize recitation session for a surah
class InitializeRecitationSession extends RecitationEvent {
  final int surahId;
  final String surahName;

  const InitializeRecitationSession({
    required this.surahId,
    required this.surahName,
  });

  @override
  List<Object?> get props => [surahId, surahName];
}

/// Start recording audio
class StartRecording extends RecitationEvent {
  const StartRecording();
}

/// Stop recording audio
class StopRecording extends RecitationEvent {
  const StopRecording();
}

/// Pause recitation (stop recording but keep session)
class PauseRecitation extends RecitationEvent {
  const PauseRecitation();
}

/// Resume recitation
class ResumeRecitation extends RecitationEvent {
  const ResumeRecitation();
}

/// Send audio chunk to server
class SendAudioChunk extends RecitationEvent {
  final List<int> audioData;

  const SendAudioChunk(this.audioData);

  @override
  List<Object?> get props => [audioData];
}

/// Received word update from server
class ReceivedWordUpdate extends RecitationEvent {
  final Map<String, dynamic> update;

  const ReceivedWordUpdate(this.update);

  @override
  List<Object?> get props => [update];
}

/// Session ready confirmation from server
class SessionReady extends RecitationEvent {
  final String sessionId;
  final int totalAyahs;
  final int totalWords;

  const SessionReady({
    required this.sessionId,
    this.totalAyahs = 0,
    this.totalWords = 0,
  });

  @override
  List<Object?> get props => [sessionId, totalAyahs, totalWords];
}

/// Error occurred
class RecitationError extends RecitationEvent {
  final String message;

  const RecitationError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Reset recitation session
class ResetRecitation extends RecitationEvent {
  const ResetRecitation();
}

/// WebSocket disconnected
class WebSocketDisconnected extends RecitationEvent {
  const WebSocketDisconnected();
}
