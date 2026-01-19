import 'package:flutter/material.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';

class VerseItem extends StatelessWidget {
  final Verse verse;

  const VerseItem({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Transparent or explicitly bg
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Verse Number & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? colorScheme.primary.withOpacity(0.2)
                      : colorScheme.primary.withOpacity(0.1),
                ),
                child: Text(
                  '${verse.numberInSurah}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary, // Teal
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.bookmark_border_rounded,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Arabic Text
          Text(
            verse.text,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
              color: isDark ? Colors.white : const Color(0xFF191919),
              height: 2.2,
            ),
          ),
          const SizedBox(height: 20),

          // Translation
          Text(
            verse.translation,
            textAlign: TextAlign.left,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark
                  ? const Color(0xFFD0D0D0)
                  : const Color(0xFF424242), // High contrast grey
              height: 1.6,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),

          // Tafseer Action (Subtle)
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: theme.cardTheme.color,
                    title: Text(
                      'Tafseer',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    content: Text(
                      'Tafseer content for verse ${verse.numberInSurah}...',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Read Tafseer',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
