import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/features/qiblah/domain/entities/nearby_mosque.dart';
import 'package:quranapp/features/qiblah/domain/entities/user_location.dart';
import 'package:quranapp/features/qiblah/domain/usecases/check_location_permission.dart';
import 'package:quranapp/features/qiblah/domain/usecases/get_current_location.dart';
import 'package:quranapp/features/qiblah/domain/usecases/get_location_stream.dart';
import 'package:quranapp/features/qiblah/domain/usecases/get_nearby_mosques.dart';

abstract class NearbyMosquesEvent extends Equatable {
  const NearbyMosquesEvent();

  @override
  List<Object?> get props => [];
}

class LoadNearbyMosquesEvent extends NearbyMosquesEvent {
  const LoadNearbyMosquesEvent();
}

class NearbyMosquesLocationUpdated extends NearbyMosquesEvent {
  final UserLocation location;

  const NearbyMosquesLocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

class NearbyMosquesErrorShown extends NearbyMosquesEvent {
  const NearbyMosquesErrorShown();
}

class NearbyMosquesLocationFailed extends NearbyMosquesEvent {
  final String message;

  const NearbyMosquesLocationFailed(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class NearbyMosquesState extends Equatable {
  const NearbyMosquesState();

  @override
  List<Object?> get props => [];
}

class NearbyMosquesInitial extends NearbyMosquesState {
  const NearbyMosquesInitial();
}

class NearbyMosquesLoading extends NearbyMosquesState {
  const NearbyMosquesLoading();
}

class NearbyMosquesPermissionDenied extends NearbyMosquesState {
  const NearbyMosquesPermissionDenied();
}

class NearbyMosquesLoaded extends NearbyMosquesState {
  final UserLocation location;
  final List<NearbyMosque> mosques;
  final bool isRefreshing;
  final String? errorMessage;

  const NearbyMosquesLoaded({
    required this.location,
    required this.mosques,
    this.isRefreshing = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [location, mosques, isRefreshing, errorMessage];
}

class NearbyMosquesError extends NearbyMosquesState {
  final String message;

  const NearbyMosquesError(this.message);

  @override
  List<Object?> get props => [message];
}

class NearbyMosquesBloc extends Bloc<NearbyMosquesEvent, NearbyMosquesState> {
  final CheckLocationPermission checkLocationPermission;
  final GetCurrentLocation getCurrentLocation;
  final GetLocationStream getLocationStream;
  final GetNearbyMosques getNearbyMosques;
  StreamSubscription? _locationSubscription;
  UserLocation? _lastLocation;
  bool _isFetching = false;

  NearbyMosquesBloc({
    required this.checkLocationPermission,
    required this.getCurrentLocation,
    required this.getLocationStream,
    required this.getNearbyMosques,
  }) : super(const NearbyMosquesInitial()) {
    on<LoadNearbyMosquesEvent>(_onLoadNearbyMosques);
    on<NearbyMosquesLocationUpdated>(_onLocationUpdated);
    on<NearbyMosquesErrorShown>(_onErrorShown);
    on<NearbyMosquesLocationFailed>(_onLocationFailed);
  }

  Future<void> _onLoadNearbyMosques(
    LoadNearbyMosquesEvent event,
    Emitter<NearbyMosquesState> emit,
  ) async {
    if (state is NearbyMosquesLoaded) {
      final current = state as NearbyMosquesLoaded;
      emit(
        NearbyMosquesLoaded(
          location: current.location,
          mosques: current.mosques,
          isRefreshing: true,
        ),
      );
    } else {
      emit(const NearbyMosquesLoading());
    }

    final permissionResult = await checkLocationPermission();
    final permissionGranted = permissionResult.fold((_) => false, (r) => r);
    if (!permissionGranted) {
      emit(const NearbyMosquesPermissionDenied());
      return;
    }

    final locationResult = await getCurrentLocation();
    final location = locationResult.fold((failure) {
      _emitFailure(failure.message, emit);
      return null;
    }, (value) => value);
    if (location == null) {
      return;
    }

    await _fetchNearby(location, emit);
    _startLocationUpdates();
  }

  Future<void> _onLocationUpdated(
    NearbyMosquesLocationUpdated event,
    Emitter<NearbyMosquesState> emit,
  ) async {
    if (_isFetching || !_shouldRefresh(event.location)) {
      return;
    }
    _lastLocation = event.location;
    if (state is NearbyMosquesLoaded) {
      final current = state as NearbyMosquesLoaded;
      emit(
        NearbyMosquesLoaded(
          location: current.location,
          mosques: current.mosques,
          isRefreshing: true,
        ),
      );
    }
    await _fetchNearby(event.location, emit);
  }

  void _onErrorShown(
    NearbyMosquesErrorShown event,
    Emitter<NearbyMosquesState> emit,
  ) {
    if (state is NearbyMosquesLoaded) {
      final current = state as NearbyMosquesLoaded;
      emit(
        NearbyMosquesLoaded(
          location: current.location,
          mosques: current.mosques,
          isRefreshing: current.isRefreshing,
        ),
      );
    }
  }

  void _onLocationFailed(
    NearbyMosquesLocationFailed event,
    Emitter<NearbyMosquesState> emit,
  ) {
    _emitFailure(event.message, emit);
  }

  Future<void> _fetchNearby(
    UserLocation location,
    Emitter<NearbyMosquesState> emit,
  ) async {
    _isFetching = true;
    final mosquesResult = await getNearbyMosques(location);
    _isFetching = false;
    mosquesResult.fold((failure) => _emitFailure(failure.message, emit), (
      mosques,
    ) {
      _lastLocation = location;
      emit(NearbyMosquesLoaded(location: location, mosques: mosques));
    });
  }

  void _emitFailure(String message, Emitter<NearbyMosquesState> emit) {
    if (state is NearbyMosquesLoaded) {
      final current = state as NearbyMosquesLoaded;
      emit(
        NearbyMosquesLoaded(
          location: current.location,
          mosques: current.mosques,
          errorMessage: message,
        ),
      );
      return;
    }
    emit(NearbyMosquesError(message));
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = getLocationStream().listen((result) {
      result.fold(
        (failure) => add(NearbyMosquesLocationFailed(failure.message)),
        (location) => add(NearbyMosquesLocationUpdated(location)),
      );
    });
  }

  bool _shouldRefresh(UserLocation next) {
    final previous = _lastLocation;
    if (previous == null) return true;
    final distance = _distanceMeters(
      previous.latitude,
      previous.longitude,
      next.latitude,
      next.longitude,
    );
    return distance >= 200;
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180;

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
