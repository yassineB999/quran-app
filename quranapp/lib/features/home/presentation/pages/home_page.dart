import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/features/home/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:quranapp/features/home/presentation/widgets/home_widgets.dart';

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

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GreetingHeader(),
            const SizedBox(height: 12),
            const ContinueReadingCard(),
            const SizedBox(height: 24),
            const DailyAyahCard(),
            const SizedBox(height: 24),
            const FeaturedSurahsSection(),
            const SizedBox(height: 24),
            const RecitationPracticeSection(),
            const SizedBox(height: 24),
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
    return const Center(
      child: Text('Settings Content', style: TextStyle(color: Colors.white)),
    );
  }
}
