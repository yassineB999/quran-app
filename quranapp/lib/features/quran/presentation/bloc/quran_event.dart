import 'package:equatable/equatable.dart';

abstract class QuranEvent extends Equatable {
  const QuranEvent();

  @override
  List<Object> get props => [];
}

class GetSurahDetailEvent extends QuranEvent {
  final int id;

  const GetSurahDetailEvent({required this.id});

  @override
  List<Object> get props => [id];
}

class GetAllSurahsEvent extends QuranEvent {}
