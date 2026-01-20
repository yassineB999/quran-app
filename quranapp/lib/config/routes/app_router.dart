import 'package:go_router/go_router.dart';
import 'package:quranapp/features/home/presentation/pages/home_page.dart';
import 'package:quranapp/features/quran/presentation/pages/surah_list_page.dart';
import 'package:quranapp/features/quran/presentation/pages/surah_detail_page.dart';
import 'package:quranapp/features/qiblah/presentation/pages/qiblah_page.dart';
import 'package:quranapp/features/quran/presentation/pages/quran_reading_page.dart';
import 'package:quranapp/features/quran/presentation/pages/mushaf_recitation_page.dart';

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
            path: '/qiblah',
            builder: (context, state) => const QiblahPage(),
          ),
          GoRoute(
            path: '/audio',
            builder: (context, state) => const SurahListPage(
              openMushafOnTap: true,
              title: 'Mushaf Recitation',
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
        builder: (context, state) => const SurahListPage(
          openMushafOnTap: true,
          title: 'Mushaf Recitation',
        ),
      ),
      GoRoute(
        path: '/mushaf/:surahId',
        builder: (context, state) {
          final surahId = int.tryParse(state.pathParameters['surahId']!) ?? 1;
          return MushafRecitationPage(surahId: surahId);
        },
      ),
    ],
  );
}
