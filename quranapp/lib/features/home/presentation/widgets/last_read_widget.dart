import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/usecases/get_reading_progress.dart';

class LastReadWidget extends StatefulWidget {
  const LastReadWidget({super.key});

  @override
  State<LastReadWidget> createState() => _LastReadWidgetState();
}

class _LastReadWidgetState extends State<LastReadWidget> {
  int? lastPage;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final result = await sl<GetReadingProgress>()(NoParams());
    result.fold(
      (l) => setState(() => loading = false),
      (page) => setState(() {
        lastPage = page;
        loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Navigate to reading page.
        // If lastPage is null, we can default to 1.
        // We use query parameter logic or simple page assumption.
        // Since we are using GoRouter with /read route which maps to QuranReadingPage(initialPage: 1),
        // we might need to pass the page.
        // But wait, the route /read logic in AppRouter might need adjustment to accept extra param?
        // Or we just push directly?
        // context.push('/read', extra: lastPage ?? 1);
        // OR construct path /read?page=X if we handled that.
        // But currently /read uses default.
        // However, QuranReadingPage(initialPage: 1) has auto-resume logic!
        // So just pushing '/read' is enough if lastPage != null.
        // If user wants to "Continue", they expect resume.
        // So context.push('/read') works perfectly with our previous implementation.
        context.push('/read');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryTeal,
              AppTheme.primaryTeal.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryTeal.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lastPage != null ? 'Last Read' : 'Start Reading',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lastPage != null ? 'Page $lastPage' : 'Begin your journey',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastPage != null
                      ? 'Continue where you left off'
                      : 'Open Quran Book',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
