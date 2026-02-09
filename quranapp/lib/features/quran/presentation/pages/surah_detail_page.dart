import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/core/widgets/error_state_widget.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_bloc.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_event.dart';
import 'package:quranapp/features/audio/presentation/widgets/media_player.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_state.dart';
import 'package:quranapp/features/quran/domain/usecases/save_reading_state.dart';
import 'package:quranapp/features/quran/presentation/widgets/verse_item.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class SurahDetailPage extends StatelessWidget {
  final int surahId;

  const SurahDetailPage({super.key, required this.surahId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<QuranBloc>()..add(GetSurahDetailEvent(id: surahId)),
        ),
        BlocProvider(
          create: (_) =>
              sl<AudioPlayerBloc>()..add(LoadAudioEvent(surahId: surahId)),
        ),
      ],
      child: _SurahDetailView(surahId: surahId),
    );
  }
}

class _SurahDetailView extends StatefulWidget {
  final int surahId;

  const _SurahDetailView({required this.surahId});

  @override
  State<_SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<_SurahDetailView> {
  late final AudioPlayerBloc _audioPlayerBloc;

  @override
  void initState() {
    super.initState();
    _audioPlayerBloc = context.read<AudioPlayerBloc>();
    sl<SaveReadingState>()(
      SaveReadingStateParams(mode: 'surah', surahId: widget.surahId),
    );
  }

  @override
  void dispose() {
    _audioPlayerBloc.add(const StopEvent());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Uses Theme
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: theme.appBarTheme.backgroundColor, // Uses Theme
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.appBarTheme.iconTheme?.color, // Uses Theme
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: BlocBuilder<QuranBloc, QuranState>(
          builder: (context, state) {
            if (state is QuranLoaded) {
              final localizedPlace = _localizeRevelationPlace(
                state.surah.revelationPlace,
                l10n,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.surah.number}. ${state.surah.name}',
                    style: theme.appBarTheme.titleTextStyle, // Uses Theme
                  ),
                  Text(
                    '${state.surah.name} • $localizedPlace',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }
            return Text(
              l10n.tr('quranReaderTitle'),
              style: theme.appBarTheme.titleTextStyle,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: theme.appBarTheme.iconTheme?.color,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<QuranBloc, QuranState>(
              builder: (context, state) {
                if (state is QuranLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                } else if (state is QuranError) {
                  return ErrorStateWidget(
                    failure: state.failure,
                    onRetry: () {
                      context.read<QuranBloc>().add(
                        GetSurahDetailEvent(id: widget.surahId),
                      );
                    },
                  );
                } else if (state is QuranLoaded) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 180),
                    itemCount: state.surah.verses.length,
                    itemBuilder: (context, index) {
                      if (index < 0 || index >= state.surah.verses.length) {
                        return const SizedBox.shrink();
                      }
                      return VerseItem(verse: state.surah.verses[index]);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      bottomSheet: const MediaPlayer(),
    );
  }
}

String _localizeRevelationPlace(String value, AppLocalizations l10n) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'meccan' ||
      normalized == 'makkah' ||
      normalized == 'makki') {
    return l10n.tr('revelationPlaceMeccan');
  }
  if (normalized == 'medinan' ||
      normalized == 'madinah' ||
      normalized == 'madani') {
    return l10n.tr('revelationPlaceMedinan');
  }
  return value;
}
