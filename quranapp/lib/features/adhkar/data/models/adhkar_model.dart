import 'package:quranapp/features/adhkar/domain/entities/adhkar.dart';

class AdhkarModel extends Adhkar {
  const AdhkarModel({
    required super.zekr,
    super.englishText,
    required super.count,
    super.reference,
    super.description,
  });

  factory AdhkarModel.fromJson(Map<String, dynamic> json) {
    int count = 1;
    if (json['count'] != null) {
      count = int.tryParse(json['count'].toString()) ?? 1;
    }

    return AdhkarModel(
      zekr: json['zekr'] ?? json['content'] ?? json['text'] ?? '',
      englishText:
          json['englishText'] ?? json['english'] ?? json['translation'],
      count: count,
      reference: json['reference'] ?? json['source'],
      description: json['description'] ?? json['bless'],
    );
  }

  factory AdhkarModel.fromEnglishJson(Map<String, dynamic> json) {
    int count = 1;
    if (json['count'] != null) {
      count = int.tryParse(json['count'].toString()) ?? 1;
    }

    return AdhkarModel(
      // The English API returns 'content' as Arabic text
      zekr: json['content'] ?? json['text'] ?? json['zekr'] ?? '',
      // And 'translation' as English text
      englishText: json['translation'] ?? json['englishText'],
      count: count,
      reference: json['reference'] ?? json['source'],
      description: json['description'],
    );
  }
}
