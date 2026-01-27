import 'package:equatable/equatable.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith_edition.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith_book.dart';

abstract class HadithState extends Equatable {
  const HadithState();

  @override
  List<Object> get props => [];
}

class HadithInitial extends HadithState {}

class HadithLoading extends HadithState {}

class HadithEditionsLoaded extends HadithState {
  final List<HadithEdition> editions;

  const HadithEditionsLoaded(this.editions);

  @override
  List<Object> get props => [editions];
}

class HadithBooksLoaded extends HadithState {
  final List<HadithBook> books;

  const HadithBooksLoaded(this.books);

  @override
  List<Object> get props => [books];
}

class HadithsLoaded extends HadithState {
  final List<Hadith> hadiths;
  final String editionId;

  const HadithsLoaded(this.hadiths, this.editionId);

  @override
  List<Object> get props => [hadiths, editionId];
}

class HadithError extends HadithState {
  final String message;

  const HadithError(this.message);

  @override
  List<Object> get props => [message];
}
