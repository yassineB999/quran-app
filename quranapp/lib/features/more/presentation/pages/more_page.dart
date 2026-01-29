import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/localization/locale_cubit.dart';
import 'package:quranapp/features/more/presentation/widgets/more_feature_card.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final features = [
      _FeatureItem(
        title: l10n.tr('qiblahLabel'),
        icon: Icons.explore_rounded,
        route: '/qiblah',
      ),
      _FeatureItem(
        title: l10n.tr('calendar'),
        icon: Icons.calendar_month_rounded,
        route: '/calendar',
      ),
      _FeatureItem(
        title: l10n.tr('hadithCollections'),
        icon: Icons.menu_book_rounded,
        // Hadith needs extra params, handled in onTap
        route: '/hadith/abudawud',
        extra: {
          'bookId': 'abudawud',
          'arabicId': 'ara-abudawud',
          'englishId': 'eng-abudawud',
        },
      ),
      _FeatureItem(
        title: l10n.tr('adhkarLabel'),
        icon: Icons.nights_stay_rounded,
        route: '/adhkar',
      ),
      // We can add more here like Mosques if available
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.tr('moreLabel'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('features'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) {
              return MoreFeatureCard(
                title: feature.title,
                icon: feature.icon,
                isDark: isDark,
                onTap: () {
                  if (feature.extra != null) {
                    context.push(feature.route, extra: feature.extra);
                  } else {
                    context.push(feature.route);
                  }
                },
              );
            }),
            const SizedBox(height: 32),
            Text(
              l10n.tr('settingsContent'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageSelector(context, l10n, theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.language, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('languageTitle'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.tr('languageSubtitle'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<LocaleCubit, Locale?>(
            builder: (context, locale) {
              final currentLocale = locale ?? const Locale('fr');
              return DropdownButtonHideUnderline(
                child: DropdownButton<Locale>(
                  value: currentLocale,
                  dropdownColor: isDark
                      ? const Color(0xFF2C2C2C)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onChanged: (value) {
                    if (value != null) {
                      context.read<LocaleCubit>().setLocale(value);
                    }
                  },
                  items: AppLocalizations.supportedLocales.map((loc) {
                    final label = _localeLabel(loc, l10n);
                    return DropdownMenuItem(
                      value: loc,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: loc == currentLocale
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _localeLabel(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case 'ar':
        return l10n.tr('languageArabic');
      case 'fr':
        return l10n.tr('languageFrench');
      case 'en':
      default:
        return l10n.tr('languageEnglish');
    }
  }
}

class _FeatureItem {
  final String title;
  final IconData icon;
  final String route;
  final Object? extra;

  const _FeatureItem({
    required this.title,
    required this.icon,
    required this.route,
    this.extra,
  });
}
