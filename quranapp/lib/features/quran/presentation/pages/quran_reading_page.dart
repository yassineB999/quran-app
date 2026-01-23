import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_bloc.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_event.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_state.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/presentation/bloc/reader/quran_reader_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/reader/quran_reader_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/reader/quran_reader_state.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class QuranReadingPage extends StatelessWidget {
  final int initialPage;

  const QuranReadingPage({super.key, this.initialPage = 1});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<QuranReaderBloc>()),
        BlocProvider(create: (_) => sl<AudioPlayerBloc>()),
      ],
      child: _QuranPageView(initialPage: initialPage),
    );
  }
}

class _QuranPageView extends StatefulWidget {
  final int initialPage;

  const _QuranPageView({required this.initialPage});

  @override
  State<_QuranPageView> createState() => _QuranPageViewState();
}

class _QuranPageViewState extends State<_QuranPageView> {
  late PageController _pageController;

  final Map<int, Verse> _selectedVerses = {};
  bool _showActionBar = false;
  bool _hasRestoredProgress = false;
  static const double _actionBarHeight = 88.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.initialPage - 1,
      viewportFraction: 0.94,
    );

    // Resume Logic: If starting from default (1), check for saved progress
    if (widget.initialPage == 1) {
      context.read<QuranReaderBloc>().add(LoadLastPageEvent());
    }

    // Onboarding Hint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tr('tipLongPress')),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleVerseSelection(Verse verse) {
    setState(() {
      if (_selectedVerses.containsKey(verse.number)) {
        _selectedVerses.remove(verse.number);
      } else {
        _selectedVerses[verse.number] = verse;
      }
      _showActionBar = _selectedVerses.isNotEmpty;
    });
  }

  void _clearSelection({bool stopAudio = false}) {
    setState(() {
      _showActionBar = false;
      _selectedVerses.clear();
    });
    if (stopAudio) {
      context.read<AudioPlayerBloc>().add(const StopEvent());
    }
  }

  List<String> _getSelectedVerseUrls() {
    final sortedVerses = _selectedVerses.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    return sortedVerses
        .map(
          (v) =>
              'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${v.number}.mp3',
        )
        .toList(growable: false);
  }

  void _playSelectedVerses() {
    if (_selectedVerses.isEmpty) return;

    final urls = _getSelectedVerseUrls();

    if (urls.isNotEmpty) {
      final l10n = AppLocalizations.of(context);
      context.read<AudioPlayerBloc>().add(PlayPlaylistEvent(urls));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.tr(
              'playingVerses',
              params: {'count': '${_selectedVerses.length}'},
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(context).viewPadding.bottom +
                (_showActionBar ? _actionBarHeight + 16 : 16),
          ),
        ),
      );
    }
  }

  void _togglePlayPause(AudioPlayerState audioState) {
    if (_selectedVerses.isEmpty) return;
    if (audioState is AudioPlayerPlaying) {
      context.read<AudioPlayerBloc>().add(const PauseEvent());
      return;
    }
    if (audioState is AudioPlayerPaused && audioState.surahId == 0) {
      context.read<AudioPlayerBloc>().add(const PlayEvent());
      return;
    }
    _playSelectedVerses();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8E7);
    final textColor = isDark ? Colors.white : Colors.black;
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final actionBarHeight = _actionBarHeight;

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocListener<QuranReaderBloc, QuranReaderState>(
        listener: (context, state) {
          // Restore progress logic
          if (!_hasRestoredProgress &&
              widget.initialPage == 1 &&
              state.lastReadPage != null) {
            final lastPage = state.lastReadPage!;
            if (lastPage > 1 && lastPage <= 604) {
              _hasRestoredProgress = true;
              // Use jumpToPage to immediately show the page
              _pageController.jumpToPage(lastPage - 1);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.tr('resumedFromPage', params: {'page': '$lastPage'}),
                  ),
                ),
              );
            }
          }
        },
        child: Stack(
          children: [
            SafeArea(
              child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
                builder: (context, state) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: _showActionBar
                          ? bottomInset + actionBarHeight + 12
                          : bottomInset + 12,
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 604,
                      allowImplicitScrolling: true,
                      onPageChanged: (index) {
                        final pageNumber = index + 1;

                        context.read<QuranReaderBloc>().add(
                          SavePageEvent(pageNumber),
                        );
                        context.read<QuranReaderBloc>().add(
                          SaveReadingStateEvent(mode: 'page', page: pageNumber),
                        );

                        if (_showActionBar) {
                          _clearSelection(stopAudio: true);
                        }
                      },
                      itemBuilder: (context, index) {
                        final pageNumber = index + 1;
                        if (!state.pages.containsKey(pageNumber) &&
                            !state.loadingPages.contains(pageNumber)) {
                          context.read<QuranReaderBloc>().add(
                            LoadPageEvent(pageNumber),
                          );
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryTeal,
                            ),
                          );
                        }
                        final verses = state.pages[pageNumber];
                        if (verses == null) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryTeal,
                            ),
                          );
                        }
                        if (verses.isEmpty) {
                          return Center(child: Text(l10n.tr('emptyPage')));
                        }

                        final page = _QuranSinglePage(
                          verses: verses,
                          pageNumber: pageNumber,
                          textColor: textColor,
                          isDark: isDark,
                          selectedVerseNumbers: _selectedVerses.keys.toSet(),
                          bottomInset: _showActionBar
                              ? bottomInset + actionBarHeight + 12
                              : bottomInset + 12,
                          onVerseTap: _toggleVerseSelection,
                        );

                        return AnimatedBuilder(
                          animation: _pageController,
                          child: page,
                          builder: (context, child) {
                            double scale = 1.0;
                            if (_pageController.position.haveDimensions) {
                              final pagePosition =
                                  _pageController.page ??
                                  _pageController.initialPage.toDouble();
                              final distance = (pagePosition - index)
                                  .abs()
                                  .clamp(0.0, 1.0);
                              scale = 1 - (distance * 0.06);
                            }
                            return Transform.scale(scale: scale, child: child);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _showActionBar
                  ? bottomInset + 12
                  : -(bottomInset + actionBarHeight + 28),
              left: 20,
              right: 20,
              child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.position != current.position,
                builder: (context, audioState) {
                  final isPlaying = audioState is AudioPlayerPlaying;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withValues(
                                  alpha: isDark ? 0.2 : 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_selectedVerses.length}',
                                style: TextStyle(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.tr('selectedVerses'),
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  l10n.tr('tapToPlay'),
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryTeal.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () => _togglePlayPause(audioState),
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                color: Colors.white,
                                tooltip: isPlaying
                                    ? l10n.tr('tapToStop')
                                    : l10n.tr('playSelectionTooltip'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                _clearSelection(stopAudio: true);
                              },
                              icon: Icon(
                                isPlaying
                                    ? Icons.stop_rounded
                                    : Icons.close_rounded,
                              ),
                              color: Colors.grey,
                              tooltip: l10n.tr('closeTooltip'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuranSinglePage extends StatefulWidget {
  final List<Verse> verses;
  final int pageNumber;
  final Color textColor;
  final bool isDark;
  final Set<int> selectedVerseNumbers;
  final double bottomInset;
  final Function(Verse) onVerseTap;

  const _QuranSinglePage({
    required this.verses,
    required this.pageNumber,
    required this.textColor,
    required this.isDark,
    required this.selectedVerseNumbers,
    required this.bottomInset,
    required this.onVerseTap,
  });

  @override
  State<_QuranSinglePage> createState() => _QuranSinglePageState();
}

class _QuranSinglePageState extends State<_QuranSinglePage> {
  final Map<int, TapGestureRecognizer> _recognizers = {};

  @override
  void didUpdateWidget(covariant _QuranSinglePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verses != widget.verses) {
      for (final recognizer in _recognizers.values) {
        recognizer.dispose();
      }
      _recognizers.clear();
    }
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textSpans = <InlineSpan>[];

    for (var verse in widget.verses) {
      final verseText = '${verse.text} ';
      final symbolText = '\uFD3F${verse.numberInSurah}\uFD3E ';
      final isSelected = widget.selectedVerseNumbers.contains(verse.number);
      final recognizer = _recognizers.putIfAbsent(
        verse.number,
        () => TapGestureRecognizer()
          ..onTap = () {
            widget.onVerseTap(verse);
          },
      );

      textSpans.add(
        TextSpan(
          text: verseText,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            height: 2.2,
            color: widget.textColor,
            backgroundColor: isSelected
                ? AppTheme.primaryTeal.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          recognizer: recognizer,
        ),
      );

      textSpans.add(
        TextSpan(
          text: symbolText,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            color: isSelected
                ? AppTheme.primaryTeal
                : AppTheme.primaryTeal.withValues(alpha: 0.7),
            backgroundColor: isSelected
                ? AppTheme.primaryTeal.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          recognizer: recognizer,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l10n.tr(
              'pageOf',
              params: {'current': '${widget.pageNumber}', 'total': '604'},
            ),
            style: TextStyle(color: widget.textColor.withValues(alpha: 0.5)),
          ),
        ),
        Expanded(
          child: _BookPageFrame(
            isDark: widget.isDark,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, widget.bottomInset),
              child: RichText(
                text: TextSpan(children: textSpans),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookPageFrame extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _BookPageFrame({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pageColor = isDark
        ? const Color(0xFF262626)
        : const Color(0xFFFFFCF2);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE7DDCC);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1C1C1C),
                          const Color(0x00262626),
                          const Color(0xFF1C1C1C),
                        ]
                      : [
                          const Color(0xFFF1E8D5),
                          const Color(0x00FFFDF6),
                          const Color(0xFFF1E8D5),
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
