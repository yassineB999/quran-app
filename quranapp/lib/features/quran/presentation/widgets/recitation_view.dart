import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/features/quran/domain/entities/recitation_word.dart';
import 'package:quranapp/features/quran/presentation/bloc/recitation/recitation_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/recitation/recitation_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/recitation/recitation_state.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// Mushaf-style recitation view.
///
/// Layout replicates a printed Quran page:
///   • Continuous flowing RichText with inline WidgetSpan ayah markers
///   • Decorative surah header cartouche
///   • Centred bismillah banner
///   • Cream parchment background with ornamental border
///   • Auto-scroll to the verse being recited
/// ──────────────────────────────────────────────────────────────────────────────
class RecitationView extends StatefulWidget {
  final VoidCallback onClose;

  const RecitationView({super.key, required this.onClose});

  @override
  State<RecitationView> createState() => _RecitationViewState();
}

class _RecitationViewState extends State<RecitationView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeVerseKey = GlobalKey();
  int _lastScrolledAyah = -1;

  // ── Mushaf colour palette ──
  static const Color _parchment = Color(0xFFFFF8E1);
  static const Color _parchmentDark = Color(0xFF1E1E1E);
  static const Color _borderBrown = Color(0xFF8B6914);
  static const Color _borderBrownDark = Color(0xFF6B5B2D);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Arabic numeral conversion ──
  String _toArabicNumber(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) => digits[int.parse(d)]).join();
  }

  // ── Group flat word list by ayah ──
  Map<int, List<RecitationWord>> _groupByAyah(List<RecitationWord> words) {
    final map = <int, List<RecitationWord>>{};
    for (final w in words) {
      map.putIfAbsent(w.ayah, () => []).add(w);
    }
    return map;
  }

  // ── Find which ayah is currently active ──
  int _findActiveAyah(List<RecitationWord> words) {
    for (final w in words) {
      if (w.status == 'active') return w.ayah;
    }
    return -1;
  }

  // ── Word colour based on status ──
  Color _wordColor(String status, bool isDark) {
    switch (status) {
      case 'correct':
        return const Color(0xFF16A34A);
      case 'mistake':
      case 'skipped': // Treat same as mistake (Tarteel-style: green/red only)
        return const Color(0xFFDC2626);
      case 'active':
        return isDark ? const Color(0xFF38BDF8) : AppTheme.primaryTeal;
      default: // pending
        return isDark ? Colors.white : Colors.black87;
    }
  }

  // ── Build the continuous-flow ayah text spans ──
  List<InlineSpan> _buildTextSpans(
    Map<int, List<RecitationWord>> grouped,
    List<int> sortedAyahs,
    int activeAyah,
    bool isDark,
  ) {
    final spans = <InlineSpan>[];

    for (final ayahNum in sortedAyahs) {
      final words = grouped[ayahNum]!;
      final isActive = ayahNum == activeAyah;

      for (final word in words) {
        spans.add(
          TextSpan(
            text: '${word.expected} ',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 24,
              height: 2.0,
              color: _wordColor(word.status, isDark),
              fontWeight: word.status == 'active'
                  ? FontWeight.bold
                  : FontWeight.normal,
              backgroundColor: word.status == 'active'
                  ? (isDark
                        ? AppTheme.primaryTeal.withValues(alpha: 0.15)
                        : AppTheme.primaryTeal.withValues(alpha: 0.08))
                  : null,
              decoration: (word.status == 'mistake' || word.status == 'skipped')
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor:
                  (word.status == 'mistake' || word.status == 'skipped')
                  ? const Color(0xFFDC2626)
                  : null,
              decorationStyle:
                  (word.status == 'mistake' || word.status == 'skipped')
                  ? TextDecorationStyle.wavy
                  : null,
            ),
          ),
        );
      }

      // ── Inline ayah marker (ornamental circle) ──
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: KeyedSubtree(
            key: isActive ? _activeVerseKey : null,
            child: _AyahMarker(
              number: _toArabicNumber(ayahNum),
              isActive: isActive,
              isDark: isDark,
            ),
          ),
        ),
      );

      // Space after marker
      spans.add(const TextSpan(text: ' '));
    }

    return spans;
  }

  // ── Auto-scroll ──
  void _scrollToActive(int activeAyah) {
    if (activeAyah < 0 || activeAyah == _lastScrolledAyah) return;
    _lastScrolledAyah = activeAyah;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _activeVerseKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.35,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _parchmentDark : _parchment;

    return BlocConsumer<RecitationBloc, RecitationState>(
      listener: (context, state) {
        if (state.words.isNotEmpty) {
          final activeAyah = _findActiveAyah(state.words);
          _scrollToActive(activeAyah);
        }
      },
      builder: (context, state) {
        if (state.status == RecitationStatus.connecting) {
          return Scaffold(
            backgroundColor: bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == RecitationStatus.error) {
          return Scaffold(
            backgroundColor: bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Error',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: widget.onClose,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        }

        final grouped = _groupByAyah(state.words);
        final sortedAyahs = grouped.keys.toList()..sort();
        final activeAyah = _findActiveAyah(state.words);

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ──
                _TopBar(
                  surahName: state.surahName,
                  accuracy: state.accuracy,
                  processedCount: state.words
                      .where((w) => w.status != 'pending')
                      .length,
                  totalWords: state.totalWords,
                  onClose: widget.onClose,
                  isDark: isDark,
                ),

                // ── Mushaf page body ──
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF252525)
                          : const Color(0xFFFFFDF5),
                      border: Border.all(
                        color: isDark ? _borderBrownDark : _borderBrown,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.brown.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Container(
                      // Inner border (double-border pattern like printed Quran)
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? _borderBrownDark.withValues(alpha: 0.5)
                              : _borderBrown.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            // ── Surah header ──
                            _SurahHeader(
                              surahName: state.surahName,
                              isDark: isDark,
                            ),

                            const SizedBox(height: 12),

                            // ── Bismillah ──
                            if (sortedAyahs.isNotEmpty)
                              _BismillahBanner(isDark: isDark),

                            const SizedBox(height: 16),

                            // ── Continuous flowing text ──
                            if (sortedAyahs.isNotEmpty)
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: RichText(
                                  textAlign: TextAlign.justify,
                                  text: TextSpan(
                                    children: _buildTextSpans(
                                      grouped,
                                      sortedAyahs,
                                      activeAyah,
                                      isDark,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Record button ──
                _RecordButton(
                  isRecording: state.isRecording,
                  isDark: isDark,
                  onPressed: () {
                    if (state.isRecording) {
                      context.read<RecitationBloc>().add(const StopRecording());
                    } else {
                      context.read<RecitationBloc>().add(
                        const StartRecording(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// ── Top bar with surah name, accuracy, and close button ──
class _TopBar extends StatelessWidget {
  final String surahName;
  final double accuracy;
  final int processedCount;
  final int totalWords;
  final VoidCallback onClose;
  final bool isDark;

  const _TopBar({
    required this.surahName,
    required this.accuracy,
    required this.processedCount,
    required this.totalWords,
    required this.onClose,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: onClose),
          const Spacer(),
          if (processedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '${accuracy.toStringAsFixed(0)}%  ·  $processedCount/$totalWords',
                style: TextStyle(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ── Decorative Surah header (gold cartouche) ──
class _SurahHeader extends StatelessWidget {
  final String surahName;
  final bool isDark;

  const _SurahHeader({required this.surahName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF3A3018),
                  const Color(0xFF4A3F20),
                  const Color(0xFF3A3018),
                ]
              : [
                  const Color(0xFFF5E6B8),
                  const Color(0xFFEBD48A),
                  const Color(0xFFF5E6B8),
                ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF8B7D3C) : const Color(0xFFDAA520),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? const Color(0xFFDAA520) : const Color(0xFFDAA520))
                .withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left ornament
          Text(
            '❁',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF8B6914),
            ),
          ),
          const SizedBox(width: 12),
          // Surah name
          Text(
            surahName.isNotEmpty ? 'سُورَةُ $surahName' : 'سُورَة',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE8D5A3) : const Color(0xFF5C4A1E),
            ),
          ),
          const SizedBox(width: 12),
          // Right ornament
          Text(
            '❁',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF8B6914),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Bismillah banner ──
class _BismillahBanner extends StatelessWidget {
  final bool isDark;
  const _BismillahBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF8B6914),
          height: 1.8,
        ),
      ),
    );
  }
}

/// ── Ornamental ayah marker ● ──
class _AyahMarker extends StatelessWidget {
  final String number;
  final bool isActive;
  final bool isDark;

  const _AyahMarker({
    required this.number,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final markerColor = isActive
        ? AppTheme.primaryTeal
        : (isDark ? const Color(0xFFD4AF37) : const Color(0xFFDAA520));

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: markerColor.withValues(alpha: isActive ? 0.15 : 0.08),
        border: Border.all(color: markerColor, width: isActive ? 2.0 : 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: markerColor,
        ),
      ),
    );
  }
}

/// ── Record / Stop button ──
class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final bool isDark;
  final VoidCallback onPressed;

  const _RecordButton({
    required this.isRecording,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: FloatingActionButton.large(
        onPressed: onPressed,
        backgroundColor: isRecording ? Colors.red : AppTheme.primaryTeal,
        elevation: isRecording ? 8 : 4,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Icon(
            isRecording ? Icons.stop_rounded : Icons.mic_rounded,
            key: ValueKey(isRecording),
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
