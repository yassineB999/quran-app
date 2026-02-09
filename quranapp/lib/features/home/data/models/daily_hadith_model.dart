import 'package:quranapp/features/home/domain/entities/daily_hadith.dart';

class DailyHadithModel extends DailyHadith {
  const DailyHadithModel({
    required super.arabic,
    required super.translation,
    required super.reference,
    super.number,
  });

  factory DailyHadithModel.fromMap(Map<String, dynamic> map) {
    return DailyHadithModel(
      arabic: map['arabic']?.toString() ?? '',
      translation: map['translation']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      number: map['number'] is int
          ? map['number'] as int
          : int.tryParse('${map['number']}'),
    );
  }
}
