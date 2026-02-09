import 'package:flutter/material.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/l10n/app_localizations.dart';

/// A reusable widget to display error states with a retry option.
///
/// This widget follows clean architecture principles by:
/// - Accepting a [Failure] object and handling localization internally
/// - Providing a consistent error UI across the app
/// - Supporting customization through optional parameters
class ErrorStateWidget extends StatelessWidget {
  /// The failure that occurred
  final Failure failure;

  /// Callback when the retry button is pressed
  final VoidCallback onRetry;

  /// Optional custom icon (defaults to error_outline)
  final IconData? icon;

  /// Optional custom icon size (defaults to 64)
  final double iconSize;

  const ErrorStateWidget({
    super.key,
    required this.failure,
    required this.onRetry,
    this.icon,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForFailure(failure),
              size: iconSize,
              color: colorScheme.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              _getLocalizedMessage(failure, l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getLocalizedHint(failure, l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tr('retry')),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the appropriate icon based on failure type
  IconData _getIconForFailure(Failure failure) {
    if (icon != null) return icon!;

    switch (failure) {
      case NetworkFailure():
        return Icons.wifi_off_rounded;
      case ServerFailure():
        return Icons.cloud_off_rounded;
      case CacheFailure():
        return Icons.storage_rounded;
      default:
        return Icons.error_outline_rounded;
    }
  }

  /// Maps failure to localized user-friendly message
  String _getLocalizedMessage(Failure failure, AppLocalizations l10n) {
    switch (failure) {
      case NetworkFailure():
        // Check if it's a timeout (slow backend) or connection issue
        if (failure.message.contains('temps') ||
            failure.message.contains('prévu') ||
            failure.message.contains('longer')) {
          return l10n.tr('serverSlowResponse');
        }
        return l10n.tr('noInternetConnection');

      case ServerFailure():
        if (failure.message.contains('Impossible') ||
            failure.message.contains('connect')) {
          return l10n.tr('serverUnavailable');
        }
        return l10n.tr('errorTryLater');

      case CacheFailure():
        return l10n.tr('cacheError');

      case ValidationFailure():
        return l10n.tr('validationError');

      default:
        return l10n.tr('errorOccurred');
    }
  }

  /// Returns a hint message below the main error
  String _getLocalizedHint(Failure failure, AppLocalizations l10n) {
    switch (failure) {
      case NetworkFailure():
        return l10n.tr('checkConnectionHint');
      case ServerFailure():
        return l10n.tr('tryAgainLaterHint');
      default:
        return '';
    }
  }
}
