import 'package:flutter/material.dart';
import 'package:quranapp/config/theme/app_theme.dart';

/// Eye toggle button for hiding/showing Quran text.
/// Positioned above system navigation bar.
class EyeToggleButton extends StatelessWidget {
  final bool isTextVisible;
  final VoidCallback onToggle;
  final bool isRecording;

  const EyeToggleButton({
    super.key,
    required this.isTextVisible,
    required this.onToggle,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isTextVisible
                ? [
                    AppTheme.primaryTeal,
                    AppTheme.primaryTeal.withValues(alpha: 0.8),
                  ]
                : [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isTextVisible ? AppTheme.primaryTeal : Colors.orange)
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isTextVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: Colors.white,
              size: 28,
            ),
            if (isRecording)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
