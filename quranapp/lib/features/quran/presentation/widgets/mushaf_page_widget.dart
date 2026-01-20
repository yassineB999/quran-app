import 'package:flutter/material.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/features/quran/domain/entities/mushaf_session.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';

/// Widget for rendering a single Mushaf page with proper Quran layout.
/// Supports hiding text while keeping ayah markers visible.
class MushafPageWidget extends StatelessWidget {
  final List<Verse> verses;
  final int pageNumber;
  final bool isTextVisible;
  final int? currentRecitingAyah;
  final Set<int> completedAyahs;
  final Map<int, AyahWordFeedback>? ayahFeedback;
  final Function(int ayahNumber)? onAyahTap;

  const MushafPageWidget({
    super.key,
    required this.verses,
    required this.pageNumber,
    this.isTextVisible = true,
    this.currentRecitingAyah,
    this.completedAyahs = const {},
    this.ayahFeedback,
    this.onAyahTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF8E7);
    final textColor = isDark ? Colors.white : Colors.black;

    if (verses.isEmpty) {
      return Container(
        color: bgColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Group verses by surah for surah headers
    final surahGroups = _groupVersesBySurah(verses);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Page number header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Page $pageNumber',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ),

          // Page content
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: surahGroups.entries.map((entry) {
                    final surahNumber = entry.key;
                    final surahVerses = entry.value;
                    final isNewSurahOnPage =
                        surahVerses.first.numberInSurah == 1;

                    return Column(
                      children: [
                        // Surah header if this is the start of a surah
                        if (isNewSurahOnPage)
                          _buildSurahHeader(surahNumber, isDark),

                        // Verses in Mushaf-style layout
                        _buildVersesLayout(surahVerses, textColor, isDark),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, List<Verse>> _groupVersesBySurah(List<Verse> verses) {
    final Map<int, List<Verse>> groups = {};
    for (var verse in verses) {
      // Extract surah number from verse (assuming we can derive it)
      // For now, we'll derive it from the global verse number pattern
      // In practice, the backend returns surah info with the verse
      final surahNum = _getSurahNumberFromVerse(verse);
      groups.putIfAbsent(surahNum, () => []);
      groups[surahNum]!.add(verse);
    }
    return groups;
  }

  int _getSurahNumberFromVerse(Verse verse) {
    // The verse.number is global (1-6236)
    // We need to derive surah from context
    // For simplicity, we'll use a lookup based on numberInSurah
    // In a real implementation, the backend should include surah_number
    // For now, this is a workaround
    return 1; // Placeholder - will be fixed when we have proper surah info
  }

  Widget _buildSurahHeader(int surahNumber, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryTeal.withValues(alpha: 0.1),
            AppTheme.goldAccent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 16, color: AppTheme.goldAccent),
          const SizedBox(width: 8),
          Text(
            'بِسْمِ ٱللَّٰهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.star, size: 16, color: AppTheme.goldAccent),
        ],
      ),
    );
  }

  Widget _buildVersesLayout(List<Verse> verses, Color textColor, bool isDark) {
    final textSpans = <InlineSpan>[];

    for (var verse in verses) {
      final isCurrentReciting = currentRecitingAyah == verse.numberInSurah;
      final isCompleted = completedAyahs.contains(verse.numberInSurah);
      final feedback = ayahFeedback?[verse.numberInSurah];

      final isCorrect = feedback?.isCorrect == true || isCompleted;
      if (isTextVisible || isCorrect) {
        textSpans.add(
          TextSpan(
            text: '${verse.text} ',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              height: 2.2,
              color: _getVerseTextColor(
                textColor,
                isCurrentReciting,
                isCompleted,
                feedback,
              ),
              backgroundColor: isCurrentReciting
                  ? AppTheme.primaryTeal.withValues(alpha: 0.1)
                  : null,
            ),
          ),
        );
      } else {
        textSpans.add(
          TextSpan(
            text: _generatePlaceholder(verse.text.length),
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              height: 2.2,
              color: Colors.transparent,
            ),
          ),
        );
      }

      // Ayah marker (always visible)
      textSpans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: onAyahTap != null
                ? () => onAyahTap!(verse.numberInSurah)
                : null,
            child: _buildAyahMarker(
              verse.numberInSurah,
              isCurrentReciting,
              isCompleted,
              feedback?.isCorrect,
              isDark,
            ),
          ),
        ),
      );

      textSpans.add(const TextSpan(text: ' '));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(children: textSpans),
      ),
    );
  }

  Color _getVerseTextColor(
    Color baseColor,
    bool isCurrentReciting,
    bool isCompleted,
    AyahWordFeedback? feedback,
  ) {
    if (feedback != null) {
      if (feedback.isCorrect) {
        return Colors.green.shade700;
      } else if (feedback.mistakeWords.isNotEmpty) {
        return Colors.red.shade700;
      }
    }

    if (isCompleted) {
      return Colors.green.shade600;
    }

    if (isCurrentReciting) {
      return AppTheme.primaryTeal;
    }

    return baseColor;
  }

  String _generatePlaceholder(int length) {
    // Generate invisible space that takes up approximate same space
    return ' ' * (length ~/ 2);
  }

  Widget _buildAyahMarker(
    int number,
    bool isCurrentReciting,
    bool isCompleted,
    bool? isCorrect,
    bool isDark,
  ) {
    Color borderColor = isDark ? Colors.white38 : Colors.black26;
    Color bgColor = Colors.transparent;
    Color textColor = isDark ? Colors.white60 : Colors.black54;

    if (isCompleted || isCorrect == true) {
      borderColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green;
    } else if (isCorrect == false) {
      borderColor = Colors.red;
      bgColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
    } else if (isCurrentReciting) {
      borderColor = AppTheme.primaryTeal;
      bgColor = AppTheme.primaryTeal.withValues(alpha: 0.1);
      textColor = AppTheme.primaryTeal;
    }

    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        _toArabicNumber(number),
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}
