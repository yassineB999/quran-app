import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/audio/presentation/bloc/recitation_bloc.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';

class RecitationPage extends StatelessWidget {
  final int surahId;
  const RecitationPage({super.key, required this.surahId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RecitationBloc(quranRepository: sl())
            ..add(LoadRecitationSurah(surahId)),
      child: const _RecitationPageView(),
    );
  }
}

class _RecitationPageView extends StatelessWidget {
  const _RecitationPageView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy
      appBar: AppBar(
        title: const Text("Memorization Coach"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocConsumer<RecitationBloc, RecitationState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.isLoading || state.surah == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // 1. Header (Surah Info)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      state
                          .surah!
                          .name, // English name? Checks surah.dart says 'name' is simple name
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${state.surah!.versesCount} Verses • ${state.surah!.revelationPlace}",
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),

              // 2. Progress Markers (Snake Path)
              Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final verses = state.ayahs;
                    const int itemsPerRow =
                        5; // Adjust based on screen width if needed
                    final int rowCount = (verses.length / itemsPerRow).ceil();

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      itemCount: rowCount,
                      itemBuilder: (context, rowIndex) {
                        final int start = rowIndex * itemsPerRow;
                        final int end = (start + itemsPerRow < verses.length)
                            ? start + itemsPerRow
                            : verses.length;
                        final rowVerses = verses.sublist(start, end);

                        // If row index is odd, reverse the list to create snake effect
                        final displayVerses = (rowIndex % 2 == 1)
                            ? rowVerses.reversed.toList()
                            : rowVerses;

                        // Handling Start/End alignment for reversed rows?
                        // Actually, just reversing the data list works for the markers.
                        // But for the last row (if incomplete) and reversed, it needs care.
                        // Snake path:
                        // 1 2 3
                        // 6 5 4
                        // 7 8 9

                        MainAxisAlignment align = MainAxisAlignment.spaceEvenly;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: align,
                            children: displayVerses.map((verse) {
                              final feedback =
                                  state.verseFeedback[verse.number];
                              final isCurrent =
                                  state.ayahs[state.currentVerseIndex].number ==
                                  verse.number;
                              return _buildVerseMarker(
                                verse,
                                feedback,
                                isCurrent,
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 3. Active Ayah Feedback Area
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Status Indicator
                      _buildConnectionStatus(state.connectionStatus),
                      const Spacer(),

                      // Ayah Text
                      if (state.ayahs.isNotEmpty)
                        _buildActiveAyahText(
                          state.ayahs[state.currentVerseIndex],
                          state,
                        ),

                      const Spacer(),

                      // Controls
                      _buildControls(context, state),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVerseMarker(
    Verse verse,
    VerseFeedback? feedback,
    bool isCurrent,
  ) {
    Color color = Colors.grey.shade200;
    Color textColor = Colors.grey;
    double scale = 1.0;

    if (isCurrent) {
      color = AppTheme.primaryTeal;
      textColor = Colors.white;
      scale = 1.2;
    } else if (feedback != null) {
      if (feedback.mistakeWords.isNotEmpty) {
        color = Colors.red.shade100;
        textColor = Colors.red;
      } else if (feedback.correctWords.isNotEmpty) {
        color = Colors.green.shade100;
        textColor = Colors.green;
      }
    }

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Text(
          "${verse.number}",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActiveAyahText(Verse verse, RecitationState state) {
    final feedback = state.verseFeedback[verse.number];
    // Split text into words (naive splitting by space)
    final words = verse.text.split(' ');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 28,
            fontFamily: 'Amiri',
            color: Colors.black87,
            height: 1.8,
          ),
          children: List.generate(words.length, (index) {
            final wordNum = index + 1;
            Color? wordColor;
            if (feedback != null) {
              if (feedback.correctWords.contains(wordNum)) {
                wordColor = Colors.green;
              } else if (feedback.mistakeWords.contains(wordNum)) {
                wordColor = Colors.red;
              }
            }

            return TextSpan(
              text: "${words[index]} ",
              style: TextStyle(
                color: wordColor,
                fontWeight: wordColor != null
                    ? FontWeight.bold
                    : FontWeight.normal,
                decoration: wordColor == Colors.red
                    ? TextDecoration.underline
                    : null,
                decorationColor: Colors.red,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(ConnectionStatus status) {
    String text;
    Color color;
    switch (status) {
      case ConnectionStatus.connected:
        text = "Listening...";
        color = Colors.green;
        break;
      case ConnectionStatus.connecting:
        text = "Connecting...";
        color = Colors.orange;
        break;
      case ConnectionStatus.failed:
        text = "Connection Failed";
        color = Colors.red;
        break;
      default:
        text = "Ready";
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, RecitationState state) {
    final bool isReciting =
        state.connectionStatus == ConnectionStatus.connected;

    return SizedBox(
      width: 80,
      height: 80,
      child: FloatingActionButton(
        onPressed: () {
          if (isReciting) {
            context.read<RecitationBloc>().add(StopRecitationSession());
          } else {
            context.read<RecitationBloc>().add(StartRecitationSession());
          }
        },
        backgroundColor: isReciting ? Colors.red : AppTheme.primaryTeal,
        child: Icon(isReciting ? Icons.stop : Icons.mic, size: 36),
      ),
    );
  }
}
