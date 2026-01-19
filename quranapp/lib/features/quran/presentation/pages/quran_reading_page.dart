import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_bloc.dart';
import 'package:quranapp/features/audio/presentation/bloc/audio_player_event.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/presentation/bloc/reader/quran_reader_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/reader/quran_reader_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/reader/quran_reader_state.dart';
import 'package:quranapp/features/quran/domain/usecases/save_reading_state.dart';

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

  List<Verse> _selectedVerses = [];
  bool _showActionBar = false;
  bool _hasRestoredProgress = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);

    // Resume Logic: If starting from default (1), check for saved progress
    if (widget.initialPage == 1) {
      context.read<QuranReaderBloc>().add(LoadLastPageEvent());
    }

    // Onboarding Hint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tip: Long press on any verse to select and play audio.',
          ),
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

  void _onSelectionChanged(List<Verse> selected) {
    if (selected.isEmpty) {
      if (_showActionBar) {
        setState(() {
          _showActionBar = false;
          _selectedVerses.clear();
        });
      }
    } else {
      // Sort by global number
      selected.sort((a, b) => a.number.compareTo(b.number));

      setState(() {
        _selectedVerses = selected;
        _showActionBar = true;
      });
    }
  }

  void _playSelectedVerses() {
    if (_selectedVerses.isEmpty) return;

    final urls = _selectedVerses
        .map(
          (v) =>
              'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${v.number}.mp3',
        )
        .toList();

    if (urls.isNotEmpty) {
      context.read<AudioPlayerBloc>().add(PlayPlaylistEvent(urls));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playing ${_selectedVerses.length} verses...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8E7);
    final textColor = isDark ? Colors.white : Colors.black;

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
                SnackBar(content: Text('Resumed from page $lastPage')),
              );
            }
          }
        },
        child: Stack(
          children: [
            SafeArea(
              child: BlocBuilder<QuranReaderBloc, QuranReaderState>(
                builder: (context, state) {
                  return PageView.builder(
                    controller: _pageController,
                    itemCount: 604,
                    onPageChanged: (index) {
                      final pageNumber = index + 1;

                      // Save Progress
                      context.read<QuranReaderBloc>().add(
                        SavePageEvent(pageNumber),
                      );
                      sl<SaveReadingState>()(
                        SaveReadingStateParams(mode: 'page', page: pageNumber),
                      );

                      if (_showActionBar) {
                        setState(() {
                          _showActionBar = false;
                          _selectedVerses.clear();
                        });
                      }
                    },
                    itemBuilder: (context, index) {
                      final pageNumber = index + 1;
                      if (!state.pages.containsKey(pageNumber)) {
                        context.read<QuranReaderBloc>().add(
                          LoadPageEvent(pageNumber),
                        );
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryTeal,
                          ),
                        );
                      }
                      final verses = state.pages[pageNumber]!;
                      if (verses.isEmpty) {
                        return const Center(child: Text("Empty Page"));
                      }

                      return _QuranSinglePage(
                        verses: verses,
                        pageNumber: pageNumber,
                        textColor: textColor,
                        onSelectionChanged: _onSelectionChanged,
                      );
                    },
                  );
                },
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _showActionBar ? 20 : -100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
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
                              'Selected Verses',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Tap to play',
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
                        IconButton(
                          onPressed: _playSelectedVerses,
                          icon: const Icon(Icons.play_arrow_rounded),
                          color: AppTheme.primaryTeal,
                          tooltip: 'Play Selection',
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showActionBar = false;
                              _selectedVerses.clear();
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.grey,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ],
                ),
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
  final Function(List<Verse>) onSelectionChanged;

  const _QuranSinglePage({
    required this.verses,
    required this.pageNumber,
    required this.textColor,
    required this.onSelectionChanged,
  });

  @override
  State<_QuranSinglePage> createState() => _QuranSinglePageState();
}

class _QuranSinglePageState extends State<_QuranSinglePage> {
  final Map<int, TextRange> _verseRanges = {};
  final Map<int, Verse> _verseMap = {};

  @override
  Widget build(BuildContext context) {
    final textSpans = <InlineSpan>[];
    int currentOffset = 0;
    int index = 0;

    _verseRanges.clear();
    _verseMap.clear();

    for (var verse in widget.verses) {
      final verseText = '${verse.text} ';
      final symbolText = '\uFD3F${verse.numberInSurah}\uFD3E ';

      textSpans.add(
        TextSpan(
          text: verseText,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            height: 2.2,
            color: widget.textColor,
          ),
        ),
      );

      final start = currentOffset;
      final end = start + verseText.length;
      _verseRanges[index] = TextRange(start: start, end: end);
      _verseMap[index] = verse;

      currentOffset += verseText.length;

      textSpans.add(
        TextSpan(
          text: symbolText,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            color: AppTheme.primaryTeal,
          ),
        ),
      );
      currentOffset += symbolText.length;
      index++;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Page ${widget.pageNumber}',
            style: TextStyle(color: widget.textColor.withValues(alpha: 0.5)),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: SingleChildScrollView(
              child: SelectableText.rich(
                TextSpan(children: textSpans),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                onSelectionChanged: (selection, cause) {
                  _handleSelection(selection);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSelection(TextSelection selection) {
    if (selection.isCollapsed) {
      widget.onSelectionChanged([]);
      return;
    }

    final selected = <Verse>{};
    _verseRanges.forEach((i, range) {
      final start = selection.baseOffset < selection.extentOffset
          ? selection.baseOffset
          : selection.extentOffset;
      final end = selection.baseOffset < selection.extentOffset
          ? selection.extentOffset
          : selection.baseOffset;

      if (start < range.end && end > range.start) {
        if (_verseMap.containsKey(i)) {
          selected.add(_verseMap[i]!);
        }
      }
    });

    final sortedList = <Verse>[];
    _verseRanges.forEach((i, range) {
      final v = _verseMap[i];
      if (v != null && selected.contains(v)) {
        sortedList.add(v);
      }
    });

    widget.onSelectionChanged(sortedList);
  }
}
