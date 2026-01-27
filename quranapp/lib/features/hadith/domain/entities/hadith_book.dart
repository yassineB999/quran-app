import 'package:equatable/equatable.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith_edition.dart';

class HadithBook extends Equatable {
  final String name;
  final HadithEdition? arabicEdition;
  final HadithEdition? englishEdition;

  const HadithBook({
    required this.name,
    this.arabicEdition,
    this.englishEdition,
  });

  String get id => name.toLowerCase().replaceAll(' ', '-');

  @override
  List<Object?> get props => [name, arabicEdition, englishEdition];
}
