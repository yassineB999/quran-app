import 'package:equatable/equatable.dart';

class RoutePoint extends Equatable {
  final double latitude;
  final double longitude;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}
