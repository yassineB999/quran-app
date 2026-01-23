import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/home/presentation/bloc/home_cubit.dart';
import 'package:quranapp/features/home/presentation/bloc/home_state.dart';
import 'package:quranapp/features/quran/domain/usecases/get_last_reading_state.dart';
import 'package:quranapp/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

// --- Greeting Header ---
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final hijriDate = state.hijriDate;
        final hijriText = hijriDate == null
            ? l10n.tr('hijriDatePlaceholder')
            : l10n.tr(
                'hijriDateFormat',
                params: {
                  'day': hijriDate.day.toString(),
                  'month': hijriDate.month,
                  'year': hijriDate.year.toString(),
                },
              );

        return SizedBox(
          height: 190,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Image(
                image: AssetImage('assets/images/screen-night.png'),
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.25),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.tr('greeting'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hijriText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          letterSpacing: 0.2,
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
    );
  }
}

class ContinueReadingCard extends StatefulWidget {
  const ContinueReadingCard({super.key});

  @override
  State<ContinueReadingCard> createState() => _ContinueReadingCardState();
}

class _ContinueReadingCardState extends State<ContinueReadingCard> {
  String title = '';
  String subtitle = '';
  bool isLoading = true;
  int? lastPage;
  int? lastSurahId;
  String readingMode = 'page';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        title = l10n.tr('defaultSurahTitle');
        subtitle = l10n.tr('defaultAyahLabel');
      });
    });
    _loadLastReadingState();
  }

  Future<void> _loadLastReadingState() async {
    try {
      final getLastReadingState = sl<GetLastReadingState>();
      final result = await getLastReadingState(NoParams());

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        result.fold((_) => setState(() => isLoading = false), (state) {
          setState(() {
            readingMode = state.mode;
            lastPage = state.page ?? 1;
            lastSurahId = state.surahId ?? 1;

            if (readingMode == 'page') {
              title = l10n.tr(
                'continueReadingPageTitle',
                params: {'page': '$lastPage'},
              );
              subtitle = l10n.tr('continueReadingSubtitleReading');
            } else {
              title = l10n.tr(
                'continueReadingSurahTitle',
                params: {'surahId': '${state.surahId}'},
              );
              subtitle = l10n.tr('continueReadingSubtitleReciting');
            }
            isLoading = false;
          });
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: () {
          if (readingMode == 'page') {
            context.push('/read');
          } else {
            context.push('/quran/$lastSurahId');
          }
        },
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            image: const DecorationImage(
              image: AssetImage('assets/images/home-continue-reading-bg.png'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.tr('lastReadLabel'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warmGreen,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            l10n.tr('continueButton'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HadithOfTheDayCard extends StatefulWidget {
  const HadithOfTheDayCard({super.key});

  @override
  State<HadithOfTheDayCard> createState() => _HadithOfTheDayCardState();
}

class _HadithOfTheDayCardState extends State<HadithOfTheDayCard> {
  bool isExpanded = false;

  String _buildShareText(HomeState state) {
    final hadith = state.dailyHadith;
    if (hadith == null) return '';
    return [
      hadith.arabic,
      hadith.translation,
      hadith.reference,
    ].where((text) => text.trim().isNotEmpty).join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final backgroundColor = isDark
        ? theme.colorScheme.surface
        : const Color(0xFFF9F7F2);

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final hadith = state.dailyHadith;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(color: borderColor, thickness: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        l10n.tr('hadithOfTheDayTitle'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          color: AppTheme.primaryTeal,
                          iconSize: 18,
                          onPressed: state.dailyHadith == null
                              ? null
                              : () {
                                  final shareText = _buildShareText(state);
                                  if (shareText.isNotEmpty) {
                                    SharePlus.instance.share(
                                      ShareParams(text: shareText),
                                    );
                                  }
                                },
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          color: AppTheme.primaryTeal,
                          iconSize: 18,
                          onPressed: state.dailyHadith == null
                              ? null
                              : () async {
                                  final shareText = _buildShareText(state);
                                  if (shareText.isEmpty) return;
                                  await Clipboard.setData(
                                    ClipboardData(text: shareText),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.tr('hadithCopiedClipboard'),
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(color: borderColor, thickness: 1),
                const SizedBox(height: 16),
                if (state.isHadithLoading)
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hadith == null)
                  Text(
                    state.hadithError ?? l10n.tr('hadithUnavailable'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTextSecondary,
                    ),
                  )
                else
                  Column(
                    children: [
                      Text(
                        hadith.arabic,
                        textAlign: TextAlign.center,
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryTeal,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          isExpanded
                              ? l10n.tr('readLess')
                              : l10n.tr('readMore'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        hadith.translation,
                        textAlign: TextAlign.center,
                        maxLines: isExpanded ? null : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hadith.reference,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Recitation Practice Section ---
class RecitationPracticeSection extends StatelessWidget {
  const RecitationPracticeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('recitationPracticeTitle'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PracticeFeaturedCard(
                  title: l10n.tr('practiceListenTitle'),
                  subtitle: l10n.tr('practiceListenSubtitle'),
                  imagePath: 'assets/images/home-practice-card-1.png',
                  buttonLabel: l10n.tr('practiceListenButton'),
                  onTap: () => context.push('/quran'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PracticeFeaturedCard(
                  title: l10n.tr('practiceMemorizationTitle'),
                  subtitle: l10n.tr('practiceMemorizationSubtitle'),
                  imagePath: 'assets/images/home-practice-card-2.png',
                  buttonLabel: l10n.tr('practiceMemorizationButton'),
                  onTap: () => context.push('/audio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PracticeFeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final String buttonLabel;
  final VoidCallback onTap;

  const _PracticeFeaturedCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
