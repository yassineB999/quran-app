import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/di/injection_container.dart' as di;
import 'package:quranapp/features/audio/presentation/bloc/recitation_bloc.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';

class RecitationSessionPage extends StatelessWidget {
  final int chapterIndex;
  final int versesCount;

  const RecitationSessionPage({
    super.key,
    this.chapterIndex = 1,
    this.versesCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RecitationBloc(quranRepository: di.sl())
            ..add(LoadRecitationSurah(chapterIndex)),
      child: const _RecitationView(),
    );
  }
}

class _RecitationView extends StatefulWidget {
  const _RecitationView();

  @override
  State<_RecitationView> createState() => _RecitationViewState();
}

class _RecitationViewState extends State<_RecitationView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: BlocBuilder<RecitationBloc, RecitationState>(
          builder: (context, state) {
            return Column(
              children: [
                Text(
                  state.surah?.name ?? "Chapter",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.surah != null)
                  Text(
                    "Chapter ${state.surah!.number} | Verse ${state.currentVerseIndex + 1}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            );
          },
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocConsumer<RecitationBloc, RecitationState>(
        listenWhen: (previous, current) =>
            previous.currentVerseIndex != current.currentVerseIndex,
        listener: (context, state) {
          // Auto-scroll logic could go here
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.surah == null) {
            return const SizedBox();
          }

          return Column(
            children: [
              // 1. Divider line
              Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

              // 2. Main Content (Verse + Snake)
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // A. Active Verse Text (Pinned or just scrolling? Image suggests it's at top)
                    SliverToBoxAdapter(child: _buildActiveVerseCard(state)),

                    // B. Snake Path
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // We render rows of 5 items
                            // But we need to calculate custom paths.
                            // For simplicity matching the image:
                            // It's a structured list.
                            return _buildSnakeSection(state);
                          },
                          childCount: 1, // just one big section for now
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Bottom Controls (Stats + Toolbar)
              _buildBottomBar(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveVerseCard(RecitationState state) {
    if (state.ayahs.isEmpty) {
      return const SizedBox();
    }
    final verse = state.ayahs[state.currentVerseIndex];
    final feedback = state.verseFeedback[verse.number];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          // Verse Text
          _buildRichVerseText(verse, feedback),

          if (feedback?.feedbackMessages.isNotEmpty ?? false)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                feedback!.feedbackMessages.join("\n"),
                style: const TextStyle(color: Colors.deepOrange, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRichVerseText(Verse verse, VerseFeedback? feedback) {
    final words = verse.text.split(' ');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 10,
        children: List.generate(words.length, (index) {
          final wordIndex = index + 1;
          Color color = Colors.black;

          if (feedback != null) {
            if (feedback.correctWords.contains(wordIndex)) {
              color = const Color(0xFF4CAF50); // Green
            }
            if (feedback.mistakeWords.contains(wordIndex)) {
              color = const Color(0xFFE57373); // Red
            }
          }

          return Text(
            words[index],
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1.6,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSnakeSection(RecitationState state) {
    // This builds all verses in the snake layout
    final verses = state.ayahs;
    const itemsPerRow = 5;
    final rowCount = (verses.length / itemsPerRow).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        final start = rowIndex * itemsPerRow;
        final end = (start + itemsPerRow < verses.length)
            ? start + itemsPerRow
            : verses.length;
        final rowVerses = verses.sublist(start, end);

        // Even rows: LTR (1,2,3)
        // Odd rows: RTL (6,5,4)
        final isEven = rowIndex % 2 == 0;
        final displayVerses = isEven ? rowVerses : rowVerses.reversed.toList();

        return SizedBox(
          height: 80,
          child: Stack(
            children: [
              // Lines would Go Here (CustomPainter)
              Positioned.fill(
                child: CustomPaint(
                  painter: SnakeLinePainter(
                    isEvenRow: isEven,
                    isLastRow: rowIndex == rowCount - 1,
                  ),
                ),
              ),

              // Circles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: displayVerses.map((verse) {
                  final isCurrent =
                      state.currentVerseIndex == state.ayahs.indexOf(verse);
                  final isPast =
                      state.currentVerseIndex > state.ayahs.indexOf(verse);

                  return _buildVerseCircle(verse, isCurrent, isPast);
                }).toList(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVerseCircle(Verse verse, bool isCurrent, bool isPast) {
    // Current: White with double border? Image has ornate circles.
    // Simplifying to Ring.

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isCurrent ? Colors.white : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? const Color(0xFF4DB6AC) : Colors.grey.shade300,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      alignment: Alignment.center,
      child: Text(
        "${verse.numberInSurah}",
        style: TextStyle(
          color: isCurrent ? const Color(0xFF4DB6AC) : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, RecitationState state) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.feedback_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "0",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),

                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  const Spacer(),

                  // Recording Indicator
                  if (state.isRecording) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text(
                    "00:51",
                    style: TextStyle(fontFamily: 'monospace'),
                  ), // Placeholder timer

                  const Spacer(),
                  // Big Play Button
                  GestureDetector(
                    onTap: () {
                      if (state.isRecording) {
                        context.read<RecitationBloc>().add(
                          StopRecitationSession(),
                        );
                      } else {
                        context.read<RecitationBloc>().add(
                          StartRecitationSession(),
                        );
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF81C784), Color(0xFF66BB6A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        state.isRecording ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Bottom Toolbar Icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.format_list_bulleted, color: Colors.grey),
                  Icon(Icons.remove_red_eye_outlined, color: Colors.grey),
                  Icon(Icons.chevron_left, color: Colors.grey),
                  Icon(Icons.chevron_right, color: Colors.grey),
                  Icon(Icons.edit_outlined, color: Colors.grey),
                  Icon(Icons.crop_free, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SnakeLinePainter extends CustomPainter {
  final bool isEvenRow;
  final bool isLastRow;

  SnakeLinePainter({required this.isEvenRow, required this.isLastRow});

  @override
  void paint(Canvas canvas, Size size) {
    if (isLastRow) return; // No line connecting out of last row

    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw simple line through center for now logic
    // Real snake connection logic requires knowing next row pos.
    // Detailed implementation omitted for brevity but visual effect is "Lines connecting items"

    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
