import 'package:equatable/equatable.dart';

abstract class MushafEvent extends Equatable {
  const MushafEvent();

  @override
  List<Object?> get props => [];
}

/// Load a surah for Mushaf display - fetches page range
class LoadSurahForMushaf extends MushafEvent {
  final int surahId;

  const LoadSurahForMushaf(this.surahId);

  @override
  List<Object?> get props => [surahId];
}

/// Load a specific page's verses
class LoadMushafPage extends MushafEvent {
  final int pageNumber;

  const LoadMushafPage(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

/// Navigate to a specific page
class NavigateToMushafPage extends MushafEvent {
  final int pageNumber;

  const NavigateToMushafPage(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

/// Toggle text visibility (eye toggle)
class ToggleTextVisibility extends MushafEvent {
  const ToggleTextVisibility();
}

/// Start a recitation session
class StartMushafRecitation extends MushafEvent {
  const StartMushafRecitation();
}

/// Stop the recitation session
class StopMushafRecitation extends MushafEvent {
  const StopMushafRecitation();
}

/// Submit audio for recitation check
class SubmitMushafRecitationAudio extends MushafEvent {
  final String filePath;

  const SubmitMushafRecitationAudio(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// Advance to the next ayah in the session
class AdvanceToNextAyah extends MushafEvent {
  const AdvanceToNextAyah();
}

/// Update the current ayah being recited
class UpdateCurrentAyah extends MushafEvent {
  final int ayahNumber;

  const UpdateCurrentAyah(this.ayahNumber);

  @override
  List<Object?> get props => [ayahNumber];
}

/// Mark current ayah as completed
class MarkAyahComplete extends MushafEvent {
  final int ayahNumber;
  final bool isCorrect;

  const MarkAyahComplete({required this.ayahNumber, required this.isCorrect});

  @override
  List<Object?> get props => [ayahNumber, isCorrect];
}
