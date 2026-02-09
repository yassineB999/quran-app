import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/hadith/presentation/bloc/hadith_bloc.dart';
import 'package:quranapp/features/hadith/presentation/bloc/hadith_event.dart';
import 'package:quranapp/features/hadith/presentation/bloc/hadith_state.dart';
import 'package:quranapp/l10n/app_localizations.dart';
import 'package:quranapp/core/widgets/error_state_widget.dart';
import 'package:share_plus/share_plus.dart';

class HadithDetailsPage extends StatelessWidget {
  final String editionId;
  final String? arabicId;
  final String? englishId;

  const HadithDetailsPage({
    super.key,
    required this.editionId,
    this.arabicId,
    this.englishId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HadithBloc>()..add(GetHadithsByEditionEvent(editionId)),
      child: _HadithDetailsView(editionId: editionId),
    );
  }
}

class _HadithDetailsView extends StatefulWidget {
  final String editionId;

  const _HadithDetailsView({required this.editionId});

  @override
  State<_HadithDetailsView> createState() => _HadithDetailsViewState();
}

class _HadithDetailsViewState extends State<_HadithDetailsView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editionId.replaceAll('-', ' ').toUpperCase()),
        actions: [
          BlocBuilder<HadithBloc, HadithState>(
            builder: (context, state) {
              if (state is HadithsLoaded && state.hadiths.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    final index = _pageController.hasClients
                        ? (_pageController.page?.round() ?? 0)
                        : 0;
                    if (index >= 0 && index < state.hadiths.length) {
                      final hadith = state.hadiths[index];
                      final text =
                          '${hadith.text}\n\n'
                          '${hadith.englishText != null && hadith.englishText!.trim().isNotEmpty ? '${hadith.englishText!}\n\n' : ''}'
                          '${hadith.narrator != null ? 'Narrated by: ${hadith.narrator}\n' : ''}'
                          '${hadith.grade != null ? 'Grade: ${hadith.grade}\n' : ''}'
                          '- Shared via Quran App';
                      SharePlus.instance.share(ShareParams(text: text));
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<HadithBloc, HadithState>(
        builder: (context, state) {
          if (state is HadithLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            );
          } else if (state is HadithError) {
            return ErrorStateWidget(
              failure: state.failure,
              onRetry: () {
                context.read<HadithBloc>().add(
                  GetHadithsByEditionEvent(widget.editionId),
                );
              },
            );
          } else if (state is HadithsLoaded) {
            if (state.hadiths.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context).tr('hadithUnavailable'),
                ),
              );
            }
            return PageView.builder(
              controller: _pageController,
              itemCount: state.hadiths.length,
              itemBuilder: (context, index) {
                final hadith = state.hadiths[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (hadith.chapter != null) ...[
                        Text(
                          hadith.chapter!,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.primaryTeal,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border:
                              Theme.of(context).brightness == Brightness.dark
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                )
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              hadith.text,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    height: 2.0,
                                    fontSize: 20,
                                    fontFamily:
                                        'Amiri', // Assuming an Arabic-friendly font is available or fallbacks nicely
                                  ),
                              textAlign: TextAlign
                                  .center, // Center checking for aesthetic
                            ),
                            if (hadith.englishText != null &&
                                hadith.englishText!.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                hadith.englishText!,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(height: 1.6),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (hadith.narrator != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryTeal.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 18,
                                color: AppTheme.primaryTeal,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  AppLocalizations.of(context).tr(
                                    'narratedBy',
                                    params: {'narrator': hadith.narrator!},
                                  ),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: AppTheme.primaryTeal,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hadith.grade != null)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Text(
                              hadith.grade!,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        '${index + 1} / ${state.hadiths.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
