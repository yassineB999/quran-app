import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_bloc.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_event.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_state.dart';

class MediaPlayer extends StatelessWidget {
  const MediaPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Info Row
              _buildInfoRow(context, state, isDark),
              const SizedBox(height: 16),

              // Progress
              _buildProgressRow(context, state, isLoading),
              const SizedBox(height: 12),

              // Controls
              _buildControlsRow(context, state, isPlaying, isLoading, isDark),

              // Error message
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.errorMessage ?? 'An error occurred',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Surah ${state.surahId}',
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
                        state.currentReciter?.name ?? 'Select Reciter',
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

        // Speed button
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
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
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
        // Repeat
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

        // Previous
        IconButton(
          onPressed: isLoading
              ? null
              : () {
                  context.read<AudioPlayerBloc>().add(
                    const PreviousSurahEvent(),
                  );
                },
          icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
        ),

        // Play/Pause
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
              : IconButton(
                  onPressed: () {
                    final bloc = context.read<AudioPlayerBloc>();
                    if (isPlaying) {
                      bloc.add(const PauseEvent());
                    } else {
                      bloc.add(const PlayEvent());
                    }
                  },
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isDark
                        ? const Color(0xFF00897B)
                        : const Color(0xFF00695C),
                    size: 36,
                  ),
                ),
        ),

        // Next
        IconButton(
          onPressed: isLoading
              ? null
              : () {
                  context.read<AudioPlayerBloc>().add(const NextSurahEvent());
                },
          icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
        ),

        // Speed indicator (small)
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
                const Text(
                  'Select Reciter',
                  style: TextStyle(
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
                const Text(
                  'Playback Speed',
                  style: TextStyle(
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
}
