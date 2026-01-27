import 'package:quranapp/features/hadith/domain/entities/hadith.dart';

class HadithModel extends Hadith {
  const HadithModel({
    required super.number,
    required super.text,
    super.englishText,
    super.narrator,
    super.grade,
    super.chapter,
  });

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    String text = '';
    if (json['text'] != null) {
      text = json['text'];
    } else if (json['body'] != null) {
      text = json['body'];
    } else if (json['hadith'] != null) {
      if (json['hadith'] is List) {
        text = (json['hadith'] as List).map((e) => e['body'] ?? '').join('\n');
      } else if (json['hadith'] is String) {
        text = json['hadith'];
      }
    }

    String? grade;
    if (json['grades'] != null && (json['grades'] as List).isNotEmpty) {
      final firstGrade = (json['grades'] as List).first;
      grade = firstGrade['grade'];
    } else {
      grade = json['grade'];
    }

    return HadithModel(
      number:
          int.tryParse(json['hadithnumber']?.toString() ?? '') ??
          json['number'] ??
          0,
      text: text,
      englishText: json['englishText'],
      narrator: json['narrator'],
      grade: grade,
      chapter: json['chapter']?['chapterTitle'],
    );
  }
}
