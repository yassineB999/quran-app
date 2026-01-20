import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/usecases/get_last_reading_state.dart';

// --- Greeting Header ---
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assalamu Alaikum,',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.lightTextSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Musab',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Continue Reading Card ---
class ContinueReadingCard extends StatefulWidget {
  const ContinueReadingCard({super.key});

  @override
  State<ContinueReadingCard> createState() => _ContinueReadingCardState();
}

class _ContinueReadingCardState extends State<ContinueReadingCard> {
  String title = 'Al-Fatihah';
  String subtitle = 'Ayah 1';
  bool isLoading = true;
  int? lastPage;
  int? lastSurahId;
  String readingMode = 'page';

  @override
  void initState() {
    super.initState();
    _loadLastReadingState();
  }

  Future<void> _loadLastReadingState() async {
    try {
      final getLastReadingState = sl<GetLastReadingState>();
      final result = await getLastReadingState(NoParams());

      if (mounted) {
        result.fold((l) => setState(() => isLoading = false), (state) {
          setState(() {
            readingMode = state.mode;
            lastPage = state.page ?? 1;
            lastSurahId = state.surahId ?? 1;

            if (readingMode == 'page') {
              title = 'Page $lastPage';
              subtitle = 'Continue Reading';
            } else {
              // For now, we only store ID, ideally we'd fetch Surah Name too.
              // But for this step, let's keep it simple or async fetch name.
              // We can map ID to name if we had the list, or just say Surah #.
              title = 'Surah #${state.surahId}';
              subtitle = 'Continue Reciting';
            }
            isLoading = false;
          });
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            context.push('/read'); // Pages handle their own state via Bloc
          } else {
            context.push('/quran/$lastSurahId');
          }
        },
        child: Container(
          height: 140,
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
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Last Read',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warmGreen,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
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

// --- Daily Ayah Card ---
class DailyAyahCard extends StatelessWidget {
  const DailyAyahCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          image: const DecorationImage(
            image: AssetImage('assets/images/home-todays-ayah-bg.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Ayah",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppTheme.primaryTeal,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Al-Fatiha, Ayah 1',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Featured Surahs Section ---
class FeaturedSurahsSection extends StatelessWidget {
  const FeaturedSurahsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Featured Surahs',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            children: const [
              _FeaturedSurahCard(
                imagePath: 'assets/images/home-featured-al-mulk.png',
                title: 'Al-Mulk',
                subtitle: 'The Sovereignty',
              ),
              SizedBox(width: 12),
              _FeaturedSurahCard(
                imagePath: 'assets/images/home-featured-al-baqarah.png',
                title: 'Al-Baqarah',
                subtitle: 'The Cow',
              ),
              SizedBox(width: 12),
              _FeaturedSurahCard(
                imagePath: 'assets/images/home-featured-al-fatiha.png',
                title: 'Al-Fatiha',
                subtitle: 'The Opener',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedSurahCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const _FeaturedSurahCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      width: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
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
        padding: const EdgeInsets.all(12),
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
          ],
        ),
      ),
    );
  }
}

// --- Recitation Practice Section ---
class RecitationPracticeSection extends StatelessWidget {
  const RecitationPracticeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recitation Practice',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PracticeFeaturedCard(
                  title: 'Listen',
                  subtitle: 'Start with any surah',
                  imagePath: 'assets/images/home-practice-card-1.png',
                  buttonLabel: 'Listen',
                  onTap: () => context.push('/quran'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PracticeFeaturedCard(
                  title: 'Memorization',
                  subtitle: 'Mushaf recitation',
                  imagePath: 'assets/images/home-practice-card-2.png',
                  buttonLabel: 'Memorize',
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
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
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
          padding: const EdgeInsets.all(12),
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
