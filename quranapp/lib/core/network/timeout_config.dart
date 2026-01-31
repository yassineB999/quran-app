/// Timeout configuration for different endpoint types
class TimeoutConfig {
  /// Fast endpoints (location, nearby, quick lookups): 10s
  static const Duration fast = Duration(seconds: 10);

  /// Medium endpoints (lists, standard API calls): 15s
  static const Duration medium = Duration(seconds: 15);

  /// Heavy endpoints (large datasets, complex queries): 30s
  static const Duration heavy = Duration(seconds: 30);

  /// Very heavy endpoints (file uploads, bulk operations): 45s
  static const Duration veryHeavy = Duration(seconds: 45);
}
