import 'package:equatable/equatable.dart';

class Verse extends Equatable {
  final int number;
  final String text; // Arabic
  final String translation; // English
  final int numberInSurah;
  final int juz;
  final int page;
  final int surahNumber;

  const Verse({
    required this.number,
    required this.text,
    required this.translation,
    required this.numberInSurah,
    required this.juz,
    required this.page,
    required this.surahNumber,
  });

  @override
  List<Object?> get props => [
    number,
    text,
    translation,
    numberInSurah,
    juz,
    page,
    surahNumber,
  ];
}

class Surah extends Equatable {
  final int number;
  final String name; // Simple name (e.g., Al-Baqarah)
  final String arabicName;
  final int versesCount;
  final String revelationPlace;
  final List<Verse> verses;

  const Surah({
    required this.number,
    required this.name,
    required this.arabicName,
    required this.versesCount,
    required this.revelationPlace,
    required this.verses,
  });

  @override
  List<Object?> get props => [
    number,
    name,
    arabicName,
    versesCount,
    revelationPlace,
    verses,
  ];
}
