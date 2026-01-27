import 'package:quranapp/features/hadith/domain/entities/hadith_edition.dart';

class HadithEditionModel extends HadithEdition {
  const HadithEditionModel({
    required super.id,
    required super.name,
    required super.collection,
    required super.language,
  });

  factory HadithEditionModel.fromJson(
    Map<String, dynamic> json, {
    String? collectionName,
  }) {
    return HadithEditionModel(
      id: json['name'] ?? '',
      name: collectionName != null
          ? '$collectionName (${json['language'] ?? ''})'
          : (json['name'] ?? ''),
      collection: collectionName ?? json['book'] ?? '',
      language: json['language'] ?? '',
    );
  }
}
