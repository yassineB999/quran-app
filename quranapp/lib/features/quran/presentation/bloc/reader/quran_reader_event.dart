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

class LoadLastPageEvent extends QuranReaderEvent {}
