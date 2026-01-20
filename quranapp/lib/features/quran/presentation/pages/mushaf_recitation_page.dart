import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/quran/presentation/bloc/mushaf/mushaf_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/mushaf/mushaf_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/mushaf/mushaf_state.dart';
import 'package:quranapp/features/quran/presentation/widgets/eye_toggle_button.dart';
import 'package:quranapp/features/quran/presentation/widgets/mushaf_audio_control_bar.dart';
import 'package:quranapp/features/quran/presentation/widgets/mushaf_page_widget.dart';
import 'package:record/record.dart';

/// Main page for Mushaf-style Quran reading with integrated recitation.
class MushafRecitationPage extends StatelessWidget {
  final int surahId;

  const MushafRecitationPage({super.key, required this.surahId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MushafBloc>()..add(LoadSurahForMushaf(surahId)),
      child: const _MushafRecitationView(),
    );
  }
}

class _MushafRecitationView extends StatefulWidget {
  const _MushafRecitationView();

  @override
  State<_MushafRecitationView> createState() => _MushafRecitationViewState();
}

class _MushafRecitationViewState extends State<_MushafRecitationView> {
  late PageController _pageController;
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/mushaf_recitation_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: filePath,
      );
      if (mounted) {
        context.read<MushafBloc>().add(const StartMushafRecitation());
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    if (mounted && path != null) {
      context.read<MushafBloc>().add(SubmitMushafRecitationAudio(path));
    } else if (mounted) {
      context.read<MushafBloc>().add(const StopMushafRecitation());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MushafBloc, MushafState>(
      listenWhen: (previous, current) =>
          previous.currentPage != current.currentPage ||
          previous.pageRange != current.pageRange,
      listener: (context, state) {
        // Sync page controller with state
        if (state.pageRange != null && _pageController.hasClients) {
          final targetIndex = state.currentPage - state.pageRange!.firstPage;
          if (_pageController.page?.round() != targetIndex) {
            _pageController.jumpToPage(targetIndex);
          }
        }
      },
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFFFF8E7);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: _buildAppBar(context, state),
          body: state.status == MushafStatus.loading
              ? Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                )
              : state.status == MushafStatus.error
              ? _buildErrorView(context, state)
              : _buildMushafContent(context, state),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, MushafState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        children: [
          Text(
            state.selectedSurah?.arabicName ?? 'Loading...',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          if (state.pageRange != null)
            Text(
              'Page ${state.currentPage} of ${state.pageRange!.lastPage}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
        ],
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: isDark ? Colors.white : Colors.black,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Session status indicator
        if (state.session.isActive)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${state.session.completedAyahs.length} done',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, MushafState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            state.errorMessage ?? 'An error occurred',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final surahId = state.selectedSurah?.number ?? 1;
              context.read<MushafBloc>().add(LoadSurahForMushaf(surahId));
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMushafContent(BuildContext context, MushafState state) {
    if (state.pageRange == null) {
      return const Center(child: Text('No pages available'));
    }

    final pageCount = state.pageRange!.pageCount;

    return Stack(
      children: [
        // PageView for Mushaf pages
        PageView.builder(
          controller: _pageController,
          itemCount: pageCount,
          onPageChanged: (index) {
            final pageNumber = state.pageRange!.firstPage + index;
            context.read<MushafBloc>().add(NavigateToMushafPage(pageNumber));
          },
          itemBuilder: (context, index) {
            final pageNumber = state.pageRange!.firstPage + index;

            // Load page if not cached
            if (!state.loadedPages.containsKey(pageNumber)) {
              context.read<MushafBloc>().add(LoadMushafPage(pageNumber));
            }

            final verses = state.loadedPages[pageNumber] ?? [];

            return MushafPageWidget(
              verses: verses,
              pageNumber: pageNumber,
              isTextVisible: state.isTextVisible,
              currentRecitingAyah: state.session.currentAyahNumberInSurah,
              completedAyahs: state.session.completedAyahs,
              ayahFeedback: state.session.ayahFeedback,
              onAyahTap: (ayahNumber) {
                context.read<MushafBloc>().add(UpdateCurrentAyah(ayahNumber));
              },
            );
          },
        ),

        // Audio control bar - shown when text is hidden
        if (!state.isTextVisible)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: MushafAudioControlBar(
              currentAyah: state.session.currentAyahNumberInSurah,
              totalAyahs: state.selectedSurah?.versesCount ?? 0,
              isRecording: state.isRecording,
              isProcessing: state.isProcessing,
              surahName: state.selectedSurah?.name,
              onStartRecording: _startRecording,
              onStopRecording: _stopRecording,
            ),
          ),

        // Page navigation controls
        if (state.isTextVisible) ...[
          // Previous page
          if (state.canGoPrevious)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () {
                    final prevPage = state.currentPage - 1;
                    context.read<MushafBloc>().add(
                      NavigateToMushafPage(prevPage),
                    );
                  },
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    size: 32,
                    color: AppTheme.primaryTeal.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),

          // Next page
          if (state.canGoNext)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: () {
                    final nextPage = state.currentPage + 1;
                    context.read<MushafBloc>().add(
                      NavigateToMushafPage(nextPage),
                    );
                  },
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    size: 32,
                    color: AppTheme.primaryTeal.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],

        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 100,
          right: 20,
          child: EyeToggleButton(
            isTextVisible: state.isTextVisible,
            isRecording: state.isRecording,
            onToggle: () {
              context.read<MushafBloc>().add(const ToggleTextVisibility());
            },
          ),
        ),
      ],
    );
  }
}
