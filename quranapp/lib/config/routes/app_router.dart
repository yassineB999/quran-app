import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/features/audio/presentation/pages/live_recitation_page.dart';
import 'package:quranapp/features/home/presentation/pages/home_page.dart';
import 'package:quranapp/features/quran/presentation/pages/surah_list_page.dart';
import 'package:quranapp/features/quran/presentation/pages/surah_detail_page.dart';
import 'package:quranapp/features/mosques/presentation/pages/mosques_page.dart';
import 'package:quranapp/features/calendar/presentation/pages/calendar_page.dart';
import 'package:quranapp/features/qiblah/presentation/pages/qiblah_page.dart';
import 'package:quranapp/features/quran/presentation/pages/quran_reading_page.dart';
import 'package:quranapp/features/quran/presentation/pages/mushaf_recitation_page.dart';
import 'package:quranapp/l10n/app_localizations.dart';

import 'package:quranapp/features/hadith/presentation/pages/hadith_details_page.dart';
import 'package:quranapp/features/more/presentation/pages/more_page.dart';
import 'package:quranapp/features/adhkar/presentation/pages/adhkar_categories_page.dart';
import 'package:quranapp/features/adhkar/presentation/pages/adhkar_list_page.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      ShellRoute(
        builder: (context, state, child) => HomeShellPage(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/quran',
            builder: (context, state) => const SurahListPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id']!) ?? 1;
                  return SurahDetailPage(surahId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/mosques',
            builder: (context, state) => const MosquesPage(),
          ),
          GoRoute(
            path: '/audio',
            builder: (context, state) => SurahListPage(
              openMushafOnTap: true,
              title: AppLocalizations.of(context).tr('mushafRecitationTitle'),
            ),
          ),
          GoRoute(path: '/more', builder: (context, state) => const MorePage()),
        ],
      ),
      GoRoute(
        path: '/read',
        builder: (context, state) => const QuranReadingPage(),
      ),
      GoRoute(
        path: '/mushaf',
        builder: (context, state) => SurahListPage(
          openMushafOnTap: true,
          title: AppLocalizations.of(context).tr('mushafRecitationTitle'),
        ),
      ),
      GoRoute(
        path: '/mushaf/:surahId',
        builder: (context, state) {
          final surahId = int.tryParse(state.pathParameters['surahId']!) ?? 1;
          final surahName = state.extra as String?;
          return MushafRecitationPage(surahId: surahId, surahName: surahName);
        },
      ),
      GoRoute(path: '/qiblah', builder: (context, state) => const QiblahPage()),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarPage(),
      ),
      GoRoute(
        path: '/hadith/:editionId',
        builder: (context, state) {
          final editionId = state.pathParameters['editionId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final arabicId = extra?['arabicId'] as String?;
          final englishId = extra?['englishId'] as String?;
          return HadithDetailsPage(
            editionId: editionId,
            arabicId: arabicId,
            englishId: englishId,
          );
        },
      ),
      GoRoute(
        path: '/adhkar',
        builder: (context, state) => const AdhkarCategoriesPage(),
      ),
      GoRoute(
        path: '/adhkar/:category',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          return AdhkarListPage(category: category);
        },
      ),
      GoRoute(
        path: '/live-recitation',
        builder: (context, state) => const LiveRecitationPage(),
      ),
    ],
  );
}
