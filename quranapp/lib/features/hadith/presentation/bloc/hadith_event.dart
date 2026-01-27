import 'package:equatable/equatable.dart';

abstract class HadithEvent extends Equatable {
  const HadithEvent();

  @override
  List<Object?> get props => [];
}

class GetHadithEditionsEvent extends HadithEvent {}

class GetHadithsByEditionEvent extends HadithEvent {
  final String editionId;

  const GetHadithsByEditionEvent(this.editionId);

  @override
  List<Object?> get props => [editionId];
}

class GetHadithsByBookEvent extends HadithEvent {
  final String bookId;
  final String? arabicEditionId;
  final String? englishEditionId;

  const GetHadithsByBookEvent({
    required this.bookId,
    this.arabicEditionId,
    this.englishEditionId,
  });

  @override
  List<Object?> get props => [bookId, arabicEditionId, englishEditionId];
}
