import 'package:equatable/equatable.dart';

class Mosque extends Equatable {
  final String id;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const Mosque({
    required this.id,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  @override
  List<Object?> get props => [id, name, city, latitude, longitude, distanceKm];
}
