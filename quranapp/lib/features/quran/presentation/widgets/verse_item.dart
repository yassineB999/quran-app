import 'package:flutter/material.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/l10n/app_localizations.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/core/network/dio_client.dart';
import 'package:quranapp/core/network/api_endpoints.dart';

class VerseItem extends StatelessWidget {
  final Verse verse;

  const VerseItem({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, // Transparent or explicitly bg
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
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
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
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
                _showTafseerBottomSheet(context, verse, theme, isDark, l10n);
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
                      l10n.tr('readTafseer'),
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

void _showTafseerBottomSheet(
  BuildContext context,
  Verse verse,
  ThemeData theme,
  bool isDark,
  AppLocalizations l10n,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.tr('tafseerTitle'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.tr('surahNumberLabel', params: {'number': '${verse.surahNumber}'})} - ${l10n.tr('ayahNumber')} ${verse.numberInSurah}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const Divider(height: 32),
              Expanded(
                child: FutureBuilder(
                  future: sl<DioClient>().get(ApiEndpoints.tafseer(verse.surahNumber, verse.numberInSurah)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: theme.colorScheme.primary),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          l10n.tr('errorTryLater'),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      );
                    } else if (snapshot.hasData) {
                      final responseData = snapshot.data?.data;
                      if (responseData == null || responseData['data'] == null || responseData['data']['tafsir_arabic'] == null) {
                        return Center(child: Text(l10n.tr('tafseerContent', params: {'verse': '${verse.numberInSurah}'})));
                      }
                      
                      final data = responseData['data'];
                      final lang = Localizations.localeOf(context).languageCode;
                      final translation = lang == 'fr' ? data['translation_french'] : data['translation_english'];

                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        children: [
                          Text(
                            data['tafsir_arabic'],
                            textAlign: TextAlign.justify,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 20,
                              height: 1.8,
                              fontFamily: 'Amiri',
                              color: isDark ? Colors.white : const Color(0xFF191919),
                            ),
                          ),
                          if (translation != null) ...[
                            const SizedBox(height: 24),
                            Text(
                              translation,
                              textAlign: TextAlign.left,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: isDark ? const Color(0xFFD0D0D0) : const Color(0xFF424242),
                                height: 1.6,
                                fontSize: 16,
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
