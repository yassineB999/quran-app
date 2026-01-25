import 'package:quranapp/features/mosques/domain/entities/mosque.dart';

class MosqueModel extends Mosque {
  const MosqueModel({
    required super.id,
    required super.name,
    required super.city,
    required super.latitude,
    required super.longitude,
    required super.distanceKm,
  });

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
    );
  }
}
