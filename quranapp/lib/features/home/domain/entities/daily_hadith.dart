import 'package:equatable/equatable.dart';

class DailyHadith extends Equatable {
  final String arabic;
  final String translation;
  final String reference;
  final int? number;

  const DailyHadith({
    required this.arabic,
    required this.translation,
    required this.reference,
    this.number,
  });

  @override
  List<Object?> get props => [arabic, translation, reference, number];
}
