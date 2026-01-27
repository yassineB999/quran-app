import 'package:equatable/equatable.dart';

class Hadith extends Equatable {
  final int number;
  final String text;
  final String? narrator;
  final String? grade;
  final String? chapter;

  final String? englishText;

  const Hadith({
    required this.number,
    required this.text,
    this.englishText,
    this.narrator,
    this.grade,
    this.chapter,
  });

  @override
  List<Object?> get props => [
    number,
    text,
    englishText,
    narrator,
    grade,
    chapter,
  ];
}
