import 'package:go_router/go_router.dart';
import 'package:quranapp/features/home/presentation/pages/home_page.dart';
import 'package:quranapp/features/quran/presentation/pages/surah_detail_page.dart';
import 'package:quranapp/features/qiblah/presentation/pages/qiblah_page.dart';
import 'package:quranapp/features/quran/presentation/pages/quran_reading_page.dart';
import 'package:quranapp/features/audio/presentation/pages/recitation_check_page.dart';

class AppRouter {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/quran/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id']!) ?? 1;
          return SurahDetailPage(surahId: id);
        },
      ),
      GoRoute(path: '/qiblah', builder: (context, state) => const QiblahPage()),
      GoRoute(
        path: '/read',
        builder: (context, state) => const QuranReadingPage(),
      ),
      GoRoute(
        path: '/live-recitation/:surahId',
        builder: (context, state) {
          return const RecitationCheckPage();
        },
      ),
    ],
  );
}
