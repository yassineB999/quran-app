import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/quran/presentation/bloc/recitation/recitation_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/recitation/recitation_event.dart';
import 'package:quranapp/features/quran/presentation/widgets/recitation_view.dart';

/// Page dedicated to the AI Recitation feature.
/// Opens directly into the recitation view for a specific Surah.
class MushafRecitationPage extends StatelessWidget {
  final int surahId;
  final String? surahName;

  const MushafRecitationPage({
    super.key,
    required this.surahId,
    this.surahName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecitationBloc>()
        ..add(
          InitializeRecitationSession(
            surahId: surahId,
            surahName: surahName ?? 'Surah $surahId',
          ),
        ),
      child: Builder(
        builder: (context) {
          return RecitationView(
            onClose: () {
              // When user closes the recitation view, we pop the page
              // RecitationBloc will be closed automatically by BlocProvider
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }
}
