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

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTS — Mushaf colour palette
// ═══════════════════════════════════════════════════════════════════════════════
const Color _parchmentLight = Color(0xFFFFFDF5);
const Color _parchmentDark = Color(0xFF252525);
const Color _frameBorderLight = Color(0xFF8B6914);
const Color _frameBorderDark = Color(0xFF6B5B2D);
const Color _goldLight = Color(0xFFDAA520);
const Color _goldDark = Color(0xFFD4AF37);
const Color _headerGradStart = Color(0xFFF5E6B8);
const Color _headerGradMid = Color(0xFFEBD48A);
const Color _headerGradStartDark = Color(0xFF3A3018);
const Color _headerGradMidDark = Color(0xFF4A3F20);

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════════
String _toArabicNumber(int number) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return number.toString().split('').map((c) => d[int.parse(c)]).join();
}

/// Lookup table of 114 Arabic surah names.
const List<String> _surahArabicNames = [
  'الفاتحة',
  'البقرة',
  'آل عمران',
  'النساء',
  'المائدة',
  'الأنعام',
  'الأعراف',
  'الأنفال',
  'التوبة',
  'يونس',
  'هود',
  'يوسف',
  'الرعد',
  'إبراهيم',
  'الحجر',
  'النحل',
  'الإسراء',
  'الكهف',
  'مريم',
  'طه',
  'الأنبياء',
  'الحج',
  'المؤمنون',
  'النور',
  'الفرقان',
  'الشعراء',
  'النمل',
  'القصص',
  'العنكبوت',
  'الروم',
  'لقمان',
  'السجدة',
  'الأحزاب',
  'سبأ',
  'فاطر',
  'يس',
  'الصافات',
  'ص',
  'الزمر',
  'غافر',
  'فصلت',
  'الشورى',
  'الزخرف',
  'الدخان',
  'الجاثية',
  'الأحقاف',
  'محمد',
  'الفتح',
  'الحجرات',
  'ق',
  'الذاريات',
  'الطور',
  'النجم',
  'القمر',
  'الرحمن',
  'الواقعة',
  'الحديد',
  'المجادلة',
  'الحشر',
  'الممتحنة',
  'الصف',
  'الجمعة',
  'المنافقون',
  'التغابن',
  'الطلاق',
  'التحريم',
  'الملك',
  'القلم',
  'الحاقة',
  'المعارج',
  'نوح',
  'الجن',
  'المزمل',
  'المدثر',
  'القيامة',
  'الإنسان',
  'المرسلات',
  'النبأ',
  'النازعات',
  'عبس',
  'التكوير',
  'الانفطار',
  'المطففين',
  'الانشقاق',
  'البروج',
  'الطارق',
  'الأعلى',
  'الغاشية',
  'الفجر',
  'البلد',
  'الشمس',
  'الليل',
  'الضحى',
  'الشرح',
  'التين',
  'العلق',
  'القدر',
  'البينة',
  'الزلزلة',
  'العاديات',
  'القارعة',
  'التكاثر',
  'العصر',
  'الهمزة',
  'الفيل',
  'قريش',
  'الماعون',
  'الكوثر',
  'الكافرون',
  'النصر',
  'المسد',
  'الإخلاص',
  'الفلق',
  'الناس',
];

/// Surahs that do NOT begin with Bismillah
const Set<int> _noBismillahSurahs = {1, 9};

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN PAGE
// ═══════════════════════════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════════════════
// PAGE VIEW
// ═══════════════════════════════════════════════════════════════════════════════
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
      viewportFraction: 1.0,
    );

    // Resume Logic
    if (widget.initialPage == 1) {
      context.read<QuranReaderBloc>().add(LoadLastPageEvent());
    }

    // Onboarding Hint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tr('tipLongPress')),
          duration: const Duration(seconds: 4),
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
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFF8E1);
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

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
                          ? bottomInset + _actionBarHeight + 12
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

                        return _MushafPage(
                          verses: verses,
                          pageNumber: pageNumber,
                          isDark: isDark,
                          selectedVerseNumbers: _selectedVerses.keys.toSet(),
                          onVerseTap: _toggleVerseSelection,
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // ── Audio action bar ──
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _showActionBar
                  ? bottomInset + 12
                  : -(bottomInset + _actionBarHeight + 28),
              left: 20,
              right: 20,
              child: _AudioActionBar(
                selectedCount: _selectedVerses.length,
                showActionBar: _showActionBar,
                isDark: isDark,
                onPlayPause: _togglePlayPause,
                onClear: () => _clearSelection(stopAudio: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MUSHAF SINGLE PAGE
// ═══════════════════════════════════════════════════════════════════════════════
class _MushafPage extends StatefulWidget {
  final List<Verse> verses;
  final int pageNumber;
  final bool isDark;
  final Set<int> selectedVerseNumbers;
  final Function(Verse) onVerseTap;

  const _MushafPage({
    required this.verses,
    required this.pageNumber,
    required this.isDark,
    required this.selectedVerseNumbers,
    required this.onVerseTap,
  });

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  final Map<int, TapGestureRecognizer> _recognizers = {};

  @override
  void didUpdateWidget(covariant _MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verses != widget.verses) {
      for (final r in _recognizers.values) {
        r.dispose();
      }
      _recognizers.clear();
    }
  }

  @override
  void dispose() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  /// Group verses by surah number to detect surah boundaries within a page.
  Map<int, List<Verse>> _groupBySurah(List<Verse> verses) {
    final map = <int, List<Verse>>{};
    for (final v in verses) {
      map.putIfAbsent(v.surahNumber, () => []).add(v);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final surahGroups = _groupBySurah(widget.verses);

    return Column(
      children: [
        // ── Page number header ──
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            _toArabicNumber(widget.pageNumber),
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 14,
              color: isDark ? _goldDark : _goldLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ── Mushaf frame ──
        Expanded(
          child: _MushafFrame(
            isDark: isDark,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: _buildPageContent(surahGroups, textColor, isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build the full page content with surah headers and verse text.
  List<Widget> _buildPageContent(
    Map<int, List<Verse>> surahGroups,
    Color textColor,
    bool isDark,
  ) {
    final widgets = <Widget>[];

    for (final entry in surahGroups.entries) {
      final surahNum = entry.key;
      final verses = entry.value;
      final startsWithAyah1 = verses.first.numberInSurah == 1;

      // If surah starts on this page, show header + bismillah
      if (startsWithAyah1) {
        // Surah header
        widgets.add(_SurahHeaderBanner(surahNumber: surahNum, isDark: isDark));
        widgets.add(const SizedBox(height: 10));

        // Bismillah (except for Surah 1 Al-Fatiha and Surah 9 At-Tawbah)
        if (!_noBismillahSurahs.contains(surahNum)) {
          widgets.add(_BismillahLine(isDark: isDark));
          widgets.add(const SizedBox(height: 12));
        }
      }

      // Continuous verse text for this surah group
      widgets.add(_buildVerseRichText(verses, textColor, isDark));
      widgets.add(const SizedBox(height: 4));
    }

    return widgets;
  }

  /// Build the continuous RichText with inline ayah markers.
  Widget _buildVerseRichText(List<Verse> verses, Color textColor, bool isDark) {
    final spans = <InlineSpan>[];

    for (final verse in verses) {
      final isSelected = widget.selectedVerseNumbers.contains(verse.number);
      final recognizer = _recognizers.putIfAbsent(
        verse.number,
        () => TapGestureRecognizer()..onTap = () => widget.onVerseTap(verse),
      );

      // Verse text
      spans.add(
        TextSpan(
          text: '${verse.text} ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            height: 2.1,
            color: isSelected ? AppTheme.primaryTeal : textColor,
            backgroundColor: isSelected
                ? AppTheme.primaryTeal.withValues(alpha: 0.1)
                : null,
          ),
          recognizer: recognizer,
        ),
      );

      // Ornamental ayah marker inline
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => widget.onVerseTap(verse),
            child: _AyahMarkerWidget(
              number: verse.numberInSurah,
              isSelected: isSelected,
              isDark: isDark,
            ),
          ),
        ),
      );

      spans.add(const TextSpan(text: ' '));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(children: spans),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MUSHAF FRAME — Double border parchment
// ═══════════════════════════════════════════════════════════════════════════════
class _MushafFrame extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _MushafFrame({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? _parchmentDark : _parchmentLight,
        border: Border.all(
          color: isDark ? _frameBorderDark : _frameBorderLight,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        // Inner border — double-border like printed Quran
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? _frameBorderDark.withValues(alpha: 0.5)
                : _frameBorderLight.withValues(alpha: 0.4),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SURAH HEADER BANNER — Gold cartouche with ornaments
// ═══════════════════════════════════════════════════════════════════════════════
class _SurahHeaderBanner extends StatelessWidget {
  final int surahNumber;
  final bool isDark;

  const _SurahHeaderBanner({required this.surahNumber, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = (surahNumber >= 1 && surahNumber <= 114)
        ? _surahArabicNames[surahNumber - 1]
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [_headerGradStartDark, _headerGradMidDark, _headerGradStartDark]
              : [_headerGradStart, _headerGradMid, _headerGradStart],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF8B7D3C) : _goldLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: _goldLight.withValues(alpha: 0.12), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Ornament(isDark: isDark),
          const SizedBox(width: 12),
          Text(
            'سُورَةُ $name',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE8D5A3) : const Color(0xFF5C4A1E),
            ),
          ),
          const SizedBox(width: 12),
          _Ornament(isDark: isDark),
        ],
      ),
    );
  }
}

class _Ornament extends StatelessWidget {
  final bool isDark;
  const _Ornament({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      '❁',
      style: TextStyle(
        fontSize: 16,
        color: isDark ? _goldDark : const Color(0xFF8B6914),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BISMILLAH LINE
// ═══════════════════════════════════════════════════════════════════════════════
class _BismillahLine extends StatelessWidget {
  final bool isDark;
  const _BismillahLine({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: isDark ? _goldDark : const Color(0xFF8B6914),
          height: 1.8,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AYAH MARKER — Ornamental golden circle
// ═══════════════════════════════════════════════════════════════════════════════
class _AyahMarkerWidget extends StatelessWidget {
  final int number;
  final bool isSelected;
  final bool isDark;

  const _AyahMarkerWidget({
    required this.number,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppTheme.primaryTeal
        : (isDark ? _goldDark : _goldLight);

    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: isSelected ? 0.12 : 0.06),
        border: Border.all(color: color, width: isSelected ? 2.0 : 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        _toArabicNumber(number),
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUDIO ACTION BAR
// ═══════════════════════════════════════════════════════════════════════════════
class _AudioActionBar extends StatelessWidget {
  final int selectedCount;
  final bool showActionBar;
  final bool isDark;
  final void Function(AudioPlayerState) onPlayPause;
  final VoidCallback onClear;

  const _AudioActionBar({
    required this.selectedCount,
    required this.showActionBar,
    required this.isDark,
    required this.onPlayPause,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : Colors.black87;

    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.position != current.position,
      builder: (context, audioState) {
        final isPlaying = audioState is AudioPlayerPlaying;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryTeal.withValues(alpha: 0.15),
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
                      '$selectedCount',
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
                          color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => onPlayPause(audioState),
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
                    onPressed: onClear,
                    icon: Icon(
                      isPlaying ? Icons.stop_rounded : Icons.close_rounded,
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
    );
  }
}
