import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';

abstract class QuranState extends Equatable {
  const QuranState();

  @override
  List<Object> get props => [];
}

class QuranInitial extends QuranState {}

class QuranLoading extends QuranState {}

class QuranLoaded extends QuranState {
  final Surah surah;

  const QuranLoaded({required this.surah});

  @override
  List<Object> get props => [surah];
}

class QuranListLoaded extends QuranState {
  final List<Surah> surahs;

  const QuranListLoaded({required this.surahs});

  @override
  List<Object> get props => [surahs];
}

/// Error state that stores the [Failure] object.
///
/// This follows clean architecture by letting the presentation layer
/// handle localization of error messages via [ErrorStateWidget].
class QuranError extends QuranState {
  final Failure failure;

  const QuranError({required this.failure});

  @override
  List<Object> get props => [failure];
}
