import 'dart:async';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/features/qiblah/domain/entities/qiblah_direction.dart';

abstract class QiblahLocalDataSource {
  Stream<QiblahDirection> getQiblahStream();
  Future<bool> requestLocationPermission();
}

class QiblahLocalDataSourceImpl implements QiblahLocalDataSource {
  static const double _kaabaLat = 21.422487;
  static const double _kaabaLng = 39.826206;

  @override
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  @override
  Stream<QiblahDirection> getQiblahStream() async* {
    // 1. Get current position (User might wait here)
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ServerException(message: 'Location services are disabled.');
    }

    // Check permission again just in case
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const ServerException(message: 'Location permission denied.');
      }
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 2. Calculate Qiblah Bearing (Static for this session usually)
    final qiblahBearing = _calculateBearing(
      position.latitude,
      position.longitude,
      _kaabaLat,
      _kaabaLng,
    );

    final distance = _calculateDistance(
      position.latitude,
      position.longitude,
      _kaabaLat,
      _kaabaLng,
    );

    // 3. Listen to compass updates
    // FlutterCompass.events can be null on some devices (simulators)
    final compassStream = FlutterCompass.events;
    if (compassStream == null) {
      throw const ServerException(message: 'Compass sensor not available.');
    }

    yield* compassStream.map((event) {
      if (event.heading == null) {
        // Should handle error or skip
        return QiblahDirection(
          qiblahBearing: qiblahBearing,
          heading: 0,
          distanceInKm: distance,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
      return QiblahDirection(
        qiblahBearing: qiblahBearing,
        heading: event.heading!,
        distanceInKm: distance,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  }

  // --- Math Helpers ---

  double _calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    // Convert to radians
    final phi1 = startLat * pi / 180;
    final lam1 = startLng * pi / 180;
    final phi2 = endLat * pi / 180;
    final lam2 = endLng * pi / 180;

    final dLam = lam2 - lam1;

    final y = sin(dLam) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLam);

    final theta = atan2(y, x);
    final bearing = (theta * 180 / pi + 360) % 360;

    return bearing;
  }

  double _calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadius = 6371.0; // km
    final dLat = (endLat - startLat) * pi / 180;
    final dLng = (endLng - startLng) * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(startLat * pi / 180) *
            cos(endLat * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
}
