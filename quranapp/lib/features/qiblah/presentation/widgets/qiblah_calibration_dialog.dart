import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class QiblahCalibrationDialog extends StatefulWidget {
  const QiblahCalibrationDialog({super.key});

  @override
  State<QiblahCalibrationDialog> createState() => _QiblahCalibrationDialogState();
}

class _QiblahCalibrationDialogState extends State<QiblahCalibrationDialog> {
  bool _dontShowAgain = false;

  void _onGotIt() async {
    if (_dontShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hide_qiblah_calibration', true);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final title = l10n.tr('qiblahCalibrationTitle');
    final message = l10n.tr('qiblahCalibrationMessage');
    final dontShowAgain = l10n.tr('qiblahCalibrationDontShowAgain');
    final gotIt = l10n.tr('gotIt');

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.screen_rotation, color: AppTheme.primaryTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          const _Figure8Animation(),
          const SizedBox(height: 32),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: _dontShowAgain,
                onChanged: (value) {
                  setState(() {
                    _dontShowAgain = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryTeal,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _dontShowAgain = !_dontShowAgain;
                    });
                  },
                  child: Text(
                    dontShowAgain,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _onGotIt,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryTeal,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          child: Text(gotIt),
        ),
      ],
    );
  }
}

class _Figure8Animation extends StatefulWidget {
  const _Figure8Animation();

  @override
  State<_Figure8Animation> createState() => _Figure8AnimationState();
}

class _Figure8AnimationState extends State<_Figure8Animation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        // Figure 8 formulas (Lissajous curves)
        final dx = math.sin(t) * 40;
        final dy = math.sin(2 * t) * 20;

        // Add some rotation to make it feel natural like a hand movement
        final rotation = math.cos(t) * 0.4;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rotation,
            child: Icon(
              Icons.smartphone,
              size: 56,
              color: AppTheme.primaryTeal.withOpacity(0.9),
            ),
          ),
        );
      },
    );
  }
}
