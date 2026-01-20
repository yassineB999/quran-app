import 'package:quranapp/features/quran/domain/entities/surah_page_range.dart';

class SurahPageRangeModel extends SurahPageRange {
  const SurahPageRangeModel({
    required super.surahNumber,
    required super.firstPage,
    required super.lastPage,
  });

  factory SurahPageRangeModel.fromJson(Map<String, dynamic> json) {
    return SurahPageRangeModel(
      surahNumber: json['surah_number'] ?? 0,
      firstPage: json['first_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah_number': surahNumber,
      'first_page': firstPage,
      'last_page': lastPage,
    };
  }
}
