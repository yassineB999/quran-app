import 'package:equatable/equatable.dart';

class Adhkar extends Equatable {
  final String zekr;
  final String? englishText;
  final int count;
  final String? reference;
  final String? description;

  const Adhkar({
    required this.zekr,
    this.englishText,
    required this.count,
    this.reference,
    this.description,
  });

  @override
  List<Object?> get props => [zekr, englishText, count, reference, description];
}
