import 'package:quranapp/features/quran/domain/entities/surah.dart';

class VerseModel extends Verse {
  const VerseModel({
    required super.number,
    required super.text,
    required super.translation,
    required super.numberInSurah,
    required super.juz,
    required super.page,
    required super.surahNumber,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    return VerseModel(
      number: json['number'] ?? 0,
      text: json['text_warsh'] ?? json['text'] ?? '',
      translation: json['translation_en'] ?? '',
      numberInSurah: json['number_in_surah'] ?? 0,
      juz: json['juz'] ?? 0,
      page: json['page'] ?? 0,
      surahNumber: json['surah_number'] ?? 0,
    );
  }
}

class SurahModel extends Surah {
  const SurahModel({
    required super.number,
    required super.name,
    required super.arabicName,
    required super.versesCount,
    required super.revelationPlace,
    required super.verses,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['number'] ?? 0,
      name: json['name_simple'] ?? '',
      arabicName: json['name_arabic'] ?? '',
      versesCount: json['verses_count'] ?? 0,
      revelationPlace: json['revelation_place'] ?? '',
      verses: json['ayahs'] != null
          ? (json['ayahs'] as List).map((v) => VerseModel.fromJson(v)).toList()
          : [],
    );
  }
}
