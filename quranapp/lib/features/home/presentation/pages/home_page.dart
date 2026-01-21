import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/core/localization/locale_cubit.dart';
import 'package:quranapp/features/home/presentation/bloc/home_cubit.dart';
import 'package:quranapp/features/home/presentation/widgets/home_widgets.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class HomeShellPage extends StatelessWidget {
  final Widget child;

  const HomeShellPage({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/quran')) return 1;
    if (location.startsWith('/qiblah')) return 2;
    if (location.startsWith('/audio')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/quran');
        break;
      case 2:
        context.go('/qiblah');
        break;
      case 3:
        context.go('/audio');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.tr('homeLabel'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            activeIcon: const Icon(Icons.menu_book),
            label: l10n.tr('quranLabel'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.view_in_ar_outlined),
            activeIcon: const Icon(Icons.view_in_ar),
            label: l10n.tr('qiblahLabel'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.lightbulb_outline),
            activeIcon: const Icon(Icons.lightbulb),
            label: l10n.tr('audioLabel'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.tr('moreLabel'),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>()..load(),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GreetingHeader(),
              const SizedBox(height: 10),
              const ContinueReadingCard(),
              const _CardDivider(),
              const SizedBox(height: 10),
              const HadithOfTheDayCard(),
              const _CardDivider(),
              const SizedBox(height: 10),
              const RecitationPracticeSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      baseColor.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      baseColor.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l10n.tr('moreLabel')), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('settingsContent'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
                  Icon(Icons.language, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.tr('languageTitle'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  BlocBuilder<LocaleCubit, Locale?>(
                    builder: (context, locale) {
                      final currentLocale = locale ?? const Locale('fr');
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<Locale>(
                          value: currentLocale,
                          onChanged: (value) {
                            if (value != null) {
                              context.read<LocaleCubit>().setLocale(value);
                            }
                          },
                          items: AppLocalizations.supportedLocales.map((loc) {
                            final label = _localeLabel(loc, l10n);
                            return DropdownMenuItem(
                              value: loc,
                              child: Text(label),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
