import 'package:quranapp/features/qiblah/domain/entities/nearby_mosque.dart';

class NearbyMosqueModel extends NearbyMosque {
  const NearbyMosqueModel({
    required super.id,
    required super.name,
    required super.city,
    required super.latitude,
    required super.longitude,
    required super.distanceKm,
  });

  factory NearbyMosqueModel.fromJson(Map<String, dynamic> json) {
    return NearbyMosqueModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
    );
  }
}
