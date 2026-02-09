import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_bloc.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_event.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_state.dart';
import 'package:quranapp/l10n/app_localizations.dart';
import 'package:quranapp/core/error/failures.dart';

class MediaPlayer extends StatelessWidget {
  const MediaPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      buildWhen: (previous, current) {
        return previous.status != current.status ||
            previous.isRepeating != current.isRepeating ||
            previous.speed != current.speed ||
            previous.position != current.position;
      },
      builder: (context, state) {
        final isPlaying = state is AudioPlayerPlaying;
        final isLoading = state is AudioPlayerLoading;
        final hasError = state is AudioPlayerError;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF1A3A3A), const Color(0xFF0D2020)]
                  : [const Color(0xFF00897B), const Color(0xFF00695C)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildInfoRow(context, state, isDark),
              const SizedBox(height: 16),
              _buildProgressRow(context, state, isLoading),
              const SizedBox(height: 12),
              _buildControlsRow(context, state, isPlaying, isLoading, isDark),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _getErrorMessage(context, state.failure) ??
                        l10n.tr('audioErrorOccurred'),
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    AudioPlayerState state,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr(
                  'surahNumberLabel',
                  params: {'number': '${state.surahId}'},
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _showReciterSelector(context, state, isDark),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        state.currentReciter?.name ?? l10n.tr('selectReciter'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _showSpeedSelector(context, state, isDark),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              '${state.speed}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(
    BuildContext context,
    AudioPlayerState state,
    bool isLoading,
  ) {
    final position = state.position;
    final duration = state.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: isLoading
                ? null
                : (value) {
                    final newPosition = Duration(
                      milliseconds: (value * duration.inMilliseconds).toInt(),
                    );
                    context.read<AudioPlayerBloc>().add(SeekEvent(newPosition));
                  },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlsRow(
    BuildContext context,
    AudioPlayerState state,
    bool isPlaying,
    bool isLoading,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: isLoading
              ? null
              : () {
                  context.read<AudioPlayerBloc>().add(
                    const ToggleRepeatEvent(),
                  );
                },
          icon: Icon(
            state.isRepeating ? Icons.repeat_one : Icons.repeat,
            color: state.isRepeating ? Colors.white : Colors.white54,
            size: 24,
          ),
        ),
        IconButton(
          onPressed: isLoading
              ? null
              : () {
                  context.read<AudioPlayerBloc>().add(
                    const PreviousSurahEvent(),
                  );
                },
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 34),
        ),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color:
                    (isDark ? const Color(0xFF00897B) : const Color(0xFF00695C))
                        .withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: isDark
                          ? const Color(0xFF00897B)
                          : const Color(0xFF00695C),
                      strokeWidth: 3,
                    ),
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    key: ValueKey(isPlaying),
                    onPressed: () {
                      final bloc = context.read<AudioPlayerBloc>();
                      if (isPlaying) {
                        bloc.add(const PauseEvent());
                      } else {
                        bloc.add(const PlayEvent());
                      }
                    },
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: isDark
                          ? const Color(0xFF00897B)
                          : const Color(0xFF00695C),
                      size: 40,
                    ),
                  ),
                ),
        ),
        IconButton(
          onPressed: isLoading
              ? null
              : () {
                  context.read<AudioPlayerBloc>().add(const NextSurahEvent());
                },
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 34),
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _showReciterSelector(
    BuildContext context,
    AudioPlayerState state,
    bool isDark,
  ) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? const Color(0xFF1A3A3A)
          : const Color(0xFF00695C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('selectReciter'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (state.availableReciters.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: state.availableReciters.length,
                      itemBuilder: (_, index) {
                        final reciter = state.availableReciters[index];
                        final isSelected =
                            reciter.id == state.currentReciter?.id;
                        return ListTile(
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: Colors.white,
                          ),
                          title: Text(
                            reciter.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            reciter.rewaya,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            context.read<AudioPlayerBloc>().add(
                              ChangeReciterEvent(
                                reciter: reciter,
                                surahId: state.surahId,
                              ),
                            );
                            Navigator.pop(bottomSheetContext);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpeedSelector(
    BuildContext context,
    AudioPlayerState state,
    bool isDark,
  ) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? const Color(0xFF1A3A3A)
          : const Color(0xFF00695C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('playbackSpeed'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: speeds.map((speed) {
                    final isSelected = state.speed == speed;
                    return ChoiceChip(
                      label: Text('${speed}x'),
                      selected: isSelected,
                      selectedColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFF1A3A3A)
                                  : const Color(0xFF00695C))
                            : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      onSelected: (_) {
                        context.read<AudioPlayerBloc>().add(
                          ChangeSpeedEvent(speed),
                        );
                        Navigator.pop(bottomSheetContext);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String? _getErrorMessage(BuildContext context, Failure? failure) {
    if (failure == null) return null;
    final l10n = AppLocalizations.of(context);
    // Reuse logic from ErrorStateWidget conceptually, or just simple mapping
    if (failure is NetworkFailure) {
      return l10n.tr('checkConnectionHint');
    } else if (failure is ServerFailure) {
      return l10n.tr('errorOccurred');
    }
    return failure.message;
  }
}
