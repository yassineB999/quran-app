import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_bloc.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_event.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_state.dart';
import 'package:quranapp/features/audio/presentation/bloc/recitation_check_cubit.dart';
import 'package:quranapp/features/audio/presentation/bloc/recitation_check_state.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:record/record.dart';

class RecitationCheckPage extends StatefulWidget {
  const RecitationCheckPage({super.key});

  @override
  State<RecitationCheckPage> createState() => _RecitationCheckPageState();
}

class _RecitationCheckPageState extends State<RecitationCheckPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording(BuildContext context) async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );
      if (context.mounted) {
        context.read<RecitationCheckCubit>().startRecording();
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission denied")),
        );
      }
    }
  }

  Future<void> _stopRecording(BuildContext context) async {
    final path = await _audioRecorder.stop();
    if (context.mounted) {
      context.read<RecitationCheckCubit>().stopRecording(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<RecitationCheckCubit>()..loadSurahs()),
        BlocProvider(create: (_) => sl<AudioPlayerBloc>()),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text("Surah Recitation")),
        body: MultiBlocListener(
          listeners: [
            BlocListener<RecitationCheckCubit, RecitationCheckState>(
              listenWhen: (previous, current) =>
                  _selectedSurahFromState(previous)?.number !=
                  _selectedSurahFromState(current)?.number,
              listener: (context, state) {
                final surah = _selectedSurahFromState(state);
                if (surah != null) {
                  context.read<AudioPlayerBloc>().add(
                    LoadAudioEvent(surahId: surah.number),
                  );
                }
              },
            ),
            BlocListener<RecitationCheckCubit, RecitationCheckState>(
              listener: (context, state) {
                if (state is RecitationCheckFailure) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
            ),
          ],
          child: BlocBuilder<RecitationCheckCubit, RecitationCheckState>(
            builder: (context, state) {
              if (state is RecitationCheckInitial ||
                  state is RecitationCheckLoadingSurahs) {
                return const Center(child: CircularProgressIndicator());
              }

              final surahs = _surahsFromState(state);
              final selectedSurah = _selectedSurahFromState(state);
              final selectedAyah = _selectedAyahFromState(state);
              final completedAyahs = _completedAyahsFromState(state);
              final ayahWordCounts = _ayahWordCountsFromState(state);
              final ayahTexts = _ayahTextsFromState(state);
              final isRecording = state is RecitationCheckRecording;
              final isProcessing = state is RecitationCheckProcessing;
              final isIncorrect =
                  state is RecitationCheckSuccess && !state.result.success;

              final theme = Theme.of(context);
              final colorScheme = theme.colorScheme;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAudioBar(context, selectedSurah),
                    const SizedBox(height: 20),
                    _buildSurahSelector(
                      context,
                      surahs,
                      selectedSurah,
                      isRecording || isProcessing,
                    ),
                    const SizedBox(height: 20),
                    if (selectedSurah != null && selectedAyah != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ayah Progress",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAyahRow(
                            context,
                            selectedSurah,
                            selectedAyah,
                            completedAyahs,
                            ayahWordCounts,
                            isRecording || isProcessing,
                          ),
                        ],
                      ),
                    if (selectedSurah != null && selectedAyah != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _buildAyahReading(
                          context,
                          selectedSurah,
                          selectedAyah,
                          completedAyahs,
                          ayahTexts,
                          ayahWordCounts,
                          isIncorrect,
                        ),
                      ),
                    const SizedBox(height: 28),
                    if (selectedSurah != null && selectedAyah != null)
                      Column(
                        children: [
                          Text(
                            "Recite Ayah $selectedAyah",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: isProcessing
                                  ? null
                                  : () {
                                      if (isRecording) {
                                        _stopRecording(context);
                                      } else {
                                        _startRecording(context);
                                      }
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: isRecording
                                      ? Colors.red.shade400
                                      : AppTheme.primaryTeal,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isRecording
                                                  ? Colors.red
                                                  : AppTheme.primaryTeal)
                                              .withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: isProcessing
                                    ? const Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        isRecording ? Icons.stop : Icons.mic,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isProcessing
                                ? "Validating..."
                                : isRecording
                                ? "Recording..."
                                : "Tap to start",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (isIncorrect && selectedAyah != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Incorrect recitation. Repeat ayah $selectedAyah",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (state is RecitationCheckSuccess)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: state.result.success
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: state.result.success
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                state.result.success
                                    ? Icons.check_circle
                                    : Icons.error_outline,
                                color: state.result.success
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.result.success
                                      ? "Ayah validated and marked complete"
                                      : "Recitation incorrect. Try again",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSurahSelector(
    BuildContext context,
    List<Surah> surahs,
    Surah? selectedSurah,
    bool isBusy,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentIndex = selectedSurah == null
        ? -1
        : surahs.indexOf(selectedSurah);

    return Row(
      children: [
        IconButton(
          onPressed: isBusy || currentIndex <= 0
              ? null
              : () {
                  context.read<RecitationCheckCubit>().selectSurah(
                    surahs[currentIndex - 1],
                  );
                },
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: DropdownButtonFormField<Surah>(
            initialValue: selectedSurah,
            decoration: InputDecoration(
              labelText: 'Select Surah',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: colorScheme.surface,
            ),
            items: surahs
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text("${s.number}. ${s.name}"),
                  ),
                )
                .toList(),
            onChanged: isBusy
                ? null
                : (val) {
                    if (val != null) {
                      context.read<RecitationCheckCubit>().selectSurah(val);
                    }
                  },
          ),
        ),
        IconButton(
          onPressed:
              isBusy || currentIndex < 0 || currentIndex >= surahs.length - 1
              ? null
              : () {
                  context.read<RecitationCheckCubit>().selectSurah(
                    surahs[currentIndex + 1],
                  );
                },
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _buildAyahRow(
    BuildContext context,
    Surah surah,
    int selectedAyah,
    List<int> completedAyahs,
    List<int> ayahWordCounts,
    bool isBusy,
  ) {
    final completedSet = completedAyahs.toSet();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(surah.versesCount, (index) {
            final ayahNumber = index + 1;
            final isCompleted = completedSet.contains(ayahNumber);
            final isSelected = ayahNumber == selectedAyah;
            final spacing = _ayahSpacing(ayahWordCounts, index);

            return Row(
              children: [
                GestureDetector(
                  onTap: isBusy
                      ? null
                      : () {
                          context.read<RecitationCheckCubit>().selectAyah(
                            ayahNumber,
                          );
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primaryTeal
                          : isSelected
                          ? AppTheme.primaryTeal.withValues(alpha: 0.1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            "$ayahNumber",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? AppTheme.primaryTeal
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                if (ayahNumber < surah.versesCount) SizedBox(width: spacing),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAyahReading(
    BuildContext context,
    Surah surah,
    int selectedAyah,
    List<int> completedAyahs,
    List<String> ayahTexts,
    List<int> ayahWordCounts,
    bool isIncorrect,
  ) {
    final completedSet = completedAyahs.toSet();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(surah.versesCount, (index) {
        final ayahNumber = index + 1;
        final isCompleted = completedSet.contains(ayahNumber);
        final isCurrent = ayahNumber == selectedAyah;
        final ayahText = index < ayahTexts.length ? ayahTexts[index] : '';
        final wordCount = index < ayahWordCounts.length
            ? ayahWordCounts[index]
            : 6;
        final borderColor = isIncorrect && isCurrent
            ? Colors.redAccent
            : isCurrent
            ? AppTheme.primaryTeal
            : colorScheme.outlineVariant.withValues(alpha: 0.4);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primaryTeal
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? AppTheme.primaryTeal
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      "$ayahNumber",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isCompleted
                            ? Colors.white
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isCompleted
                    ? Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          ayahText.isNotEmpty ? ayahText : " ",
                          key: ValueKey("ayah_$ayahNumber"),
                          textAlign: TextAlign.justify,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'Amiri',
                            height: 1.8,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      )
                    : _buildAyahPlaceholder(context, wordCount, ayahNumber),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAyahPlaceholder(
    BuildContext context,
    int wordCount,
    int ayahNumber,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final placeholderCount = wordCount.clamp(3, 16);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(placeholderCount, (index) {
          final width = 20 + (index % 4) * 10;
          return Container(
            key: ValueKey("placeholder_${ayahNumber}_$index"),
            width: width.toDouble(),
            height: 12,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }

  double _ayahSpacing(List<int> wordCounts, int index) {
    if (index >= wordCounts.length) return 14;
    final count = wordCounts[index].clamp(2, 18);
    return 10 + (count - 2) * 1.8;
  }

  Widget _buildAudioBar(BuildContext context, Surah? selectedSurah) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        final isLoading =
            state is AudioPlayerLoading || state is AudioPlayerInitial;
        final isPlaying = state is AudioPlayerPlaying;
        final hasError = state is AudioPlayerError;
        final duration = state.duration;
        final position = state.position;
        final hasDuration = duration.inMilliseconds > 0;
        final progress = hasDuration
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedSurah != null
                              ? "${selectedSurah.number}. ${selectedSurah.name}"
                              : "Select Surah",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.currentReciter?.name ?? "Loading reciter...",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (isPlaying) {
                              context.read<AudioPlayerBloc>().add(
                                const PauseEvent(),
                              );
                            } else {
                              context.read<AudioPlayerBloc>().add(
                                const PlayEvent(),
                              );
                            }
                          },
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 32,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: isLoading || !hasDuration
                    ? null
                    : (value) {
                        final newPosition = Duration(
                          milliseconds: (value * duration.inMilliseconds)
                              .toInt(),
                        );
                        context.read<AudioPlayerBloc>().add(
                          SeekEvent(newPosition),
                        );
                      },
                activeColor: AppTheme.primaryTeal,
                inactiveColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Loading audio...",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    state.errorMessage ?? "Audio failed to load",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  List<Surah> _surahsFromState(RecitationCheckState state) {
    if (state is RecitationCheckSurahsLoaded) return state.surahs;
    if (state is RecitationCheckRecording) return state.surahs;
    if (state is RecitationCheckProcessing) return state.surahs;
    if (state is RecitationCheckSuccess) return state.surahs;
    if (state is RecitationCheckFailure) return state.surahs;
    return const [];
  }

  Surah? _selectedSurahFromState(RecitationCheckState state) {
    if (state is RecitationCheckSurahsLoaded) return state.selectedSurah;
    if (state is RecitationCheckRecording) return state.selectedSurah;
    if (state is RecitationCheckProcessing) return state.selectedSurah;
    if (state is RecitationCheckSuccess) return state.selectedSurah;
    if (state is RecitationCheckFailure) return state.selectedSurah;
    return null;
  }

  int? _selectedAyahFromState(RecitationCheckState state) {
    if (state is RecitationCheckSurahsLoaded) return state.selectedAyah;
    if (state is RecitationCheckRecording) return state.selectedAyah;
    if (state is RecitationCheckProcessing) return state.selectedAyah;
    if (state is RecitationCheckSuccess) return state.selectedAyah;
    if (state is RecitationCheckFailure) return state.selectedAyah;
    return null;
  }

  List<int> _completedAyahsFromState(RecitationCheckState state) {
    if (state is RecitationCheckSurahsLoaded) return state.completedAyahs;
    if (state is RecitationCheckRecording) return state.completedAyahs;
    if (state is RecitationCheckProcessing) return state.completedAyahs;
    if (state is RecitationCheckSuccess) return state.completedAyahs;
    if (state is RecitationCheckFailure) return state.completedAyahs;
    return const [];
  }

  List<int> _ayahWordCountsFromState(RecitationCheckState state) {
    if (state is RecitationCheckSurahsLoaded) return state.ayahWordCounts;
    if (state is RecitationCheckRecording) return state.ayahWordCounts;
    if (state is RecitationCheckProcessing) return state.ayahWordCounts;
    if (state is RecitationCheckSuccess) return state.ayahWordCounts;
    if (state is RecitationCheckFailure) return state.ayahWordCounts;
    return const [];
  }

  List<String> _ayahTextsFromState(RecitationCheckState state) {
    if (state is RecitationCheckSurahsLoaded) return state.ayahTexts;
    if (state is RecitationCheckRecording) return state.ayahTexts;
    if (state is RecitationCheckProcessing) return state.ayahTexts;
    if (state is RecitationCheckSuccess) return state.ayahTexts;
    if (state is RecitationCheckFailure) return state.ayahTexts;
    return const [];
  }
}
