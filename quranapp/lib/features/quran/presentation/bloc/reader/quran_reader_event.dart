import 'package:equatable/equatable.dart';

abstract class QuranReaderEvent extends Equatable {
  const QuranReaderEvent();

  @override
  List<Object> get props => [];
}

class LoadPageEvent extends QuranReaderEvent {
  final int pageNumber;

  const LoadPageEvent(this.pageNumber);

  @override
  List<Object> get props => [pageNumber];
}

class SavePageEvent extends QuranReaderEvent {
  final int pageNumber;

  const SavePageEvent(this.pageNumber);

  @override
  List<Object> get props => [pageNumber];
}

class SaveReadingStateEvent extends QuranReaderEvent {
  final String mode;
  final int? page;
  final int? surahId;

  const SaveReadingStateEvent({required this.mode, this.page, this.surahId});

  @override
  List<Object> get props => [mode, page ?? 0, surahId ?? 0];
}

class LoadLastPageEvent extends QuranReaderEvent {}
