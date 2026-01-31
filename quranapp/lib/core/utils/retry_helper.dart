import 'dart:async';
import 'dart:math' as math;

/// Helper class for implementing retry logic with exponential backoff
class RetryHelper {
  /// Executes an action with automatic retry on failure
  ///
  /// [action] - The async function to execute
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay before first retry (default: 1s)
  /// [maxDelay] - Maximum delay between retries (default: 10s)
  ///
  /// Returns the result of the action if successful
  /// Throws the last exception if all attempts fail
  static Future<T> withRetry<T>({
    required Future<T> Function() action,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxAttempts) {
      try {
        return await action();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempt++;

        if (attempt >= maxAttempts) {
          throw lastException;
        }

        // Exponential backoff: 1s, 2s, 4s, 8s (capped at maxDelay)
        final delay = Duration(
          milliseconds: math.min(
            initialDelay.inMilliseconds * math.pow(2, attempt - 1).toInt(),
            maxDelay.inMilliseconds,
          ),
        );

        await Future.delayed(delay);
      }
    }

    throw lastException ?? Exception('Retry failed');
  }
}
