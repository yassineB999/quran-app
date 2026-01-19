import 'package:flutter/material.dart';

import 'package:quranapp/features/home/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:quranapp/features/home/presentation/widgets/home_widgets.dart';
import 'package:quranapp/features/quran/presentation/pages/surah_list_page.dart';
import 'package:quranapp/features/qiblah/presentation/pages/qiblah_page.dart';
import 'package:quranapp/features/audio/presentation/pages/recitation_check_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 0: Home (Placeholder)
          // 0: Home UI
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: 100,
              ), // Space for bottom nav
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
          ),
          // 1: Quran
          const SurahListPage(),
          // 2: Qiblah
          const QiblahPage(),
          // 3: Audio (Placeholder)
          // 3: Audio (Digital Coach - Demo Surah 1)
          const RecitationCheckPage(),
          // 4: More (Placeholder)
          const Center(
            child: Text(
              'Settings Content',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
