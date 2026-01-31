import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/location/domain/entities/user_location.dart';
import 'package:quranapp/core/location/domain/usecases/check_location_permission.dart';
import 'package:quranapp/core/location/domain/usecases/get_current_location.dart';
import 'package:quranapp/core/location/domain/usecases/get_location_stream.dart';
import 'package:quranapp/core/network/connectivity_service.dart';
import 'package:quranapp/features/mosques/domain/entities/mosque.dart';
import 'package:quranapp/features/mosques/domain/usecases/get_nearby_mosques.dart';

// Events
abstract class MosqueEvent extends Equatable {
  const MosqueEvent();

  @override
  List<Object?> get props => [];
}

class LoadMosquesEvent extends MosqueEvent {
  const LoadMosquesEvent();
}

class MosqueLocationUpdated extends MosqueEvent {
  final UserLocation location;

  const MosqueLocationUpdated(this.location);

  @override
  List<Object?> get props => [location];
}

class MosqueErrorShown extends MosqueEvent {
  const MosqueErrorShown();
}

class MosqueLocationFailed extends MosqueEvent {
  final String message;

  const MosqueLocationFailed(this.message);

  @override
  List<Object?> get props => [message];
}

// State
abstract class MosqueState extends Equatable {
  const MosqueState();

  @override
  List<Object?> get props => [];
}

class MosqueInitial extends MosqueState {
  const MosqueInitial();
}

class MosqueLoading extends MosqueState {
  const MosqueLoading();
}

class MosquePermissionDenied extends MosqueState {
  const MosquePermissionDenied();
}

class MosqueLoaded extends MosqueState {
  final UserLocation location;
  final List<Mosque> mosques;
  final bool isRefreshing;
  final String? errorMessage;

  const MosqueLoaded({
    required this.location,
    required this.mosques,
    this.isRefreshing = false,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [location, mosques, isRefreshing, errorMessage];
}

class MosqueError extends MosqueState {
  final String message;

  const MosqueError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class MosqueBloc extends Bloc<MosqueEvent, MosqueState> {
  final CheckLocationPermission checkLocationPermission;
  final GetCurrentLocation getCurrentLocation;
  final GetLocationStream getLocationStream;
  final GetNearbyMosques getNearbyMosques;
  final ConnectivityService connectivityService;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _connectivitySubscription;
  UserLocation? _lastLocation;
  bool _isFetching = false;

  MosqueBloc({
    required this.checkLocationPermission,
    required this.getCurrentLocation,
    required this.getLocationStream,
    required this.getNearbyMosques,
    required this.connectivityService,
  }) : super(const MosqueInitial()) {
    on<LoadMosquesEvent>(_onLoadMosques);
    on<MosqueLocationUpdated>(_onLocationUpdated);
    on<MosqueErrorShown>(_onErrorShown);
    on<MosqueLocationFailed>(_onLocationFailed);
    _setupAutoRetry();
  }

  void _setupAutoRetry() {
    _connectivitySubscription = connectivityService.stateStream.listen((state) {
      if (state is ConnectivityOnline) {
        if (this.state is MosqueError ||
            (this.state is MosqueLoaded &&
                (this.state as MosqueLoaded).errorMessage != null)) {
          add(const LoadMosquesEvent());
        }
      }
    });
  }

  Future<void> _onLoadMosques(
    LoadMosquesEvent event,
    Emitter<MosqueState> emit,
  ) async {
    if (state is MosqueLoaded) {
      final current = state as MosqueLoaded;
      emit(
        MosqueLoaded(
          location: current.location,
          mosques: current.mosques,
          isRefreshing: true,
        ),
      );
    } else {
      emit(const MosqueLoading());
    }

    final permissionResult = await checkLocationPermission();
    final permissionGranted = permissionResult.fold((_) => false, (r) => r);
    if (!permissionGranted) {
      emit(const MosquePermissionDenied());
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
    MosqueLocationUpdated event,
    Emitter<MosqueState> emit,
  ) async {
    if (_isFetching || !_shouldRefresh(event.location)) {
      return;
    }
    _lastLocation = event.location;
    if (state is MosqueLoaded) {
      final current = state as MosqueLoaded;
      emit(
        MosqueLoaded(
          location: current.location,
          mosques: current.mosques,
          isRefreshing: true,
        ),
      );
    }
    await _fetchNearby(event.location, emit);
  }

  void _onErrorShown(MosqueErrorShown event, Emitter<MosqueState> emit) {
    if (state is MosqueLoaded) {
      final current = state as MosqueLoaded;
      emit(
        MosqueLoaded(
          location: current.location,
          mosques: current.mosques,
          isRefreshing: current.isRefreshing,
        ),
      );
    }
  }

  void _onLocationFailed(
    MosqueLocationFailed event,
    Emitter<MosqueState> emit,
  ) {
    _emitFailure(event.message, emit);
  }

  Future<void> _fetchNearby(
    UserLocation location,
    Emitter<MosqueState> emit,
  ) async {
    _isFetching = true;
    final mosquesResult = await getNearbyMosques(location: location);
    _isFetching = false;
    mosquesResult.fold((failure) => _emitFailure(failure.message, emit), (
      mosques,
    ) {
      _lastLocation = location;
      emit(MosqueLoaded(location: location, mosques: mosques));
    });
  }

  void _emitFailure(String message, Emitter<MosqueState> emit) {
    if (state is MosqueLoaded) {
      final current = state as MosqueLoaded;
      emit(
        MosqueLoaded(
          location: current.location,
          mosques: current.mosques,
          errorMessage: message,
        ),
      );
      return;
    }
    emit(MosqueError(message));
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = getLocationStream().listen(
      (result) {
        // Check if Bloc is still active before adding events
        if (!isClosed) {
          result.fold(
            (failure) => add(MosqueLocationFailed(failure.message)),
            (location) => add(MosqueLocationUpdated(location)),
          );
        }
      },
      onError: (_) {
        // Silently handle stream errors to prevent crashes
      },
    );
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
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
