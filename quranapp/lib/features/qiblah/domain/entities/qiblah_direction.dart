import 'package:equatable/equatable.dart';

class QiblahDirection extends Equatable {
  final double qiblahBearing; // Angle to Kaaba from True North (0-360)
  final double heading; // Phone's current heading (0-360)
  final double distanceInKm;
  final double latitude;
  final double longitude;

  const QiblahDirection({
    required this.qiblahBearing,
    required this.heading,
    required this.distanceInKm,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [
    qiblahBearing,
    heading,
    distanceInKm,
    latitude,
    longitude,
  ];
}
