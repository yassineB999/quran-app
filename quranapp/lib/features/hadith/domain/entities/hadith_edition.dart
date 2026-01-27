import 'package:equatable/equatable.dart';

class HadithEdition extends Equatable {
  final String id;
  final String name;
  final String collection;
  final String language;

  const HadithEdition({
    required this.id,
    required this.name,
    required this.collection,
    required this.language,
  });

  @override
  List<Object?> get props => [id, name, collection, language];
}
