import 'package:flutter/material.dart';
import 'package:quranapp/core/network/connectivity_service.dart';

/// Global offline/error banner widget that overlays the app
class OfflineBanner extends StatelessWidget {
  final ConnectivityService connectivityService;

  const OfflineBanner({super.key, required this.connectivityService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityState>(
      stream: connectivityService.stateStream,
      initialData: connectivityService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? const ConnectivityOnline();

        // Don't show banner when online
        if (state is ConnectivityOnline) {
          return const SizedBox.shrink();
        }

        return _buildBanner(context, state);
      },
    );
  }

  Widget _buildBanner(BuildContext context, ConnectivityState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String message;
    IconData icon;
    Color backgroundColor;
    Color textColor;

    if (state is ConnectivityOfflineWaiting) {
      message = 'Pas de connexion Internet. En attente de reconnexion…';
      icon = Icons.wifi_off_rounded;
      backgroundColor = isDark
          ? const Color(0xFF4A4A4A)
          : const Color(0xFF757575);
      textColor = Colors.white;
    } else if (state is ConnectivityOfflineExtended) {
      message = 'Toujours hors ligne…';
      icon = Icons.cloud_off_rounded;
      backgroundColor = isDark
          ? const Color(0xFF5A5A5A)
          : const Color(0xFF616161);
      textColor = Colors.white;
    } else if (state is ConnectivitySlowBackend) {
      message = 'Le serveur met plus de temps que prévu…';
      icon = Icons.access_time_rounded;
      backgroundColor = isDark
          ? const Color(0xFF5D4E37)
          : const Color(0xFFFFA726);
      textColor = isDark ? Colors.white : Colors.black87;
    } else if (state is ConnectivityBackendRetrying) {
      message =
          'Impossible de se connecter pour le moment. Nous réessayons automatiquement…';
      icon = Icons.sync_rounded;
      backgroundColor = isDark
          ? const Color(0xFF5D4E37)
          : const Color(0xFFFFA726);
      textColor = isDark ? Colors.white : Colors.black87;
    } else if (state is ConnectivityBackendFailed) {
      message = 'Une erreur est survenue. Veuillez réessayer plus tard.';
      icon = Icons.error_outline_rounded;
      backgroundColor = isDark
          ? const Color(0xFF6D4C41)
          : const Color(0xFFEF5350);
      textColor = Colors.white;
    } else {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (state is ConnectivityBackendRetrying)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
