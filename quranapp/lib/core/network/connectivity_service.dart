import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connectivity states for the app
abstract class ConnectivityState {
  const ConnectivityState();
}

class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

class ConnectivityOfflineWaiting extends ConnectivityState {
  const ConnectivityOfflineWaiting();
}

class ConnectivityOfflineExtended extends ConnectivityState {
  const ConnectivityOfflineExtended();
}

class ConnectivitySlowBackend extends ConnectivityState {
  const ConnectivitySlowBackend();
}

class ConnectivityBackendRetrying extends ConnectivityState {
  final int attemptNumber;
  const ConnectivityBackendRetrying(this.attemptNumber);
}

class ConnectivityBackendFailed extends ConnectivityState {
  const ConnectivityBackendFailed();
}

/// Global connectivity monitoring service
class ConnectivityService {
  final Connectivity _connectivity;

  final _stateController = StreamController<ConnectivityState>.broadcast();
  Stream<ConnectivityState> get stateStream => _stateController.stream;

  ConnectivityState _currentState = const ConnectivityOnline();
  ConnectivityState get currentState => _currentState;

  Timer? _offlineTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  ConnectivityService({required Connectivity connectivity})
    : _connectivity = connectivity {
    _initialize();
  }

  void _initialize() {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _handleConnectivityChange(result);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = !results.contains(ConnectivityResult.none);

    if (isConnected) {
      // Back online
      _offlineTimer?.cancel();
      _updateState(const ConnectivityOnline());
      if (kDebugMode) {
        print('🌐 ConnectivityService: Online');
      }
    } else {
      // Gone offline
      _updateState(const ConnectivityOfflineWaiting());
      if (kDebugMode) {
        print('📴 ConnectivityService: Offline (waiting)');
      }

      // After 30 seconds, switch to extended offline
      _offlineTimer?.cancel();
      _offlineTimer = Timer(const Duration(seconds: 30), () {
        if (_currentState is ConnectivityOfflineWaiting) {
          _updateState(const ConnectivityOfflineExtended());
          if (kDebugMode) {
            print('📴 ConnectivityService: Offline (extended)');
          }
        }
      });
    }
  }

  void _updateState(ConnectivityState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Check if currently online
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Manually trigger slow backend state
  void notifySlowBackend() {
    _updateState(const ConnectivitySlowBackend());
    if (kDebugMode) {
      print('🐌 ConnectivityService: Slow backend detected');
    }
  }

  /// Notify that backend retry is happening
  void notifyBackendRetrying(int attemptNumber) {
    _updateState(ConnectivityBackendRetrying(attemptNumber));
    if (kDebugMode) {
      print('🔄 ConnectivityService: Backend retry attempt $attemptNumber');
    }
  }

  /// Notify that backend failed after retries
  void notifyBackendFailed() {
    _updateState(const ConnectivityBackendFailed());
    if (kDebugMode) {
      print('❌ ConnectivityService: Backend failed after retries');
    }
  }

  /// Reset to online state (useful after successful recovery)
  void resetToOnline() {
    _offlineTimer?.cancel();
    _updateState(const ConnectivityOnline());
  }

  void dispose() {
    _offlineTimer?.cancel();
    _connectivitySubscription?.cancel();
    _stateController.close();
  }
}
