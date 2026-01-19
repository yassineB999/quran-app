/// Abstraction for checking network connectivity.
/// This allows for easier testing and clean architecture compliance.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Stub implementation of NetworkInfo.
/// To enable real connectivity checking, add connectivity_plus package:
///   flutter pub add connectivity_plus
/// Then implement using Connectivity().checkConnectivity()
///
/// For now, we rely on Dio's error handling for network issues.
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected => Future.value(true);
}
