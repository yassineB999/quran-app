import 'package:flutter/material.dart';
import 'package:quranapp/config/theme/app_theme.dart';

/// Audio control bar shown when text is hidden during recitation.
class MushafAudioControlBar extends StatelessWidget {
  final int currentAyah;
  final int totalAyahs;
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final String? surahName;

  const MushafAudioControlBar({
    super.key,
    required this.currentAyah,
    required this.totalAyahs,
    required this.isRecording,
    required this.isProcessing,
    required this.onStartRecording,
    required this.onStopRecording,
    this.surahName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with surah info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: AppTheme.primaryTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahName ?? 'Recitation Mode',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ayah $currentAyah of $totalAyahs',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Recording indicator
              if (isRecording)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'REC',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress indicator
          LinearProgressIndicator(
            value: totalAyahs > 0 ? currentAyah / totalAyahs : 0,
            backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryTeal),
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 20),

          // Record button
          GestureDetector(
            onTap: isProcessing
                ? null
                : (isRecording ? onStopRecording : onStartRecording),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRecording
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording ? Colors.red : Colors.green).withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isProcessing
                ? 'Checking recitation...'
                : isRecording
                ? 'Tap to stop'
                : 'Tap to start reciting',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
