import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/qiblah/presentation/bloc/qiblah_bloc.dart';
import 'package:quranapp/features/qiblah/presentation/bloc/qiblah_state.dart';
import 'package:quranapp/features/qiblah/presentation/widgets/compass_widget.dart';
import 'package:quranapp/features/qiblah/presentation/widgets/qiblah_calibration_dialog.dart';
import 'package:quranapp/core/widgets/error_state_widget.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class QiblahPage extends StatelessWidget {
  const QiblahPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QiblahBloc>()..add(InitQiblahEvent()),
      child: const _QiblahView(),
    );
  }
}

class _QiblahView extends StatefulWidget {
  const _QiblahView();

  @override
  State<_QiblahView> createState() => _QiblahViewState();
}

class _QiblahViewState extends State<_QiblahView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCalibrationDialog();
    });
  }

  Future<void> _checkCalibrationDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final dontShow = prefs.getBool('hide_qiblah_calibration') ?? false;
    
    if (!dontShow && mounted) {
      showDialog(
        context: context,
        builder: (context) => const QiblahCalibrationDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.tr('qiblahLabel')), elevation: 0),
      body: BlocBuilder<QiblahBloc, QiblahState>(
        builder: (context, state) {
          if (state is QiblahLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            );
          } else if (state is QiblahError) {
            return ErrorStateWidget(
              failure: state.failure,
              onRetry: () {
                context.read<QiblahBloc>().add(InitQiblahEvent());
              },
            );
          } else if (state is QiblahLoaded) {
            final data = state.direction;
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(height: 20),
                // Compass UI
                Expanded(
                  flex: 3,
                  child: Center(
                    child: CompassWidget(
                      heading: data.heading,
                      qiblahBearing: data.qiblahBearing,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
