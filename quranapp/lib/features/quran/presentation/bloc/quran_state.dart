import 'package:equatable/equatable.dart';
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

class QuranError extends QuranState {
  final String message;

  const QuranError({required this.message});

  @override
  List<Object> get props => [message];
}
