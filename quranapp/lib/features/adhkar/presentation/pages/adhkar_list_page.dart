import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/adhkar/presentation/bloc/adhkar_bloc.dart';
import 'package:quranapp/features/adhkar/presentation/bloc/adhkar_event.dart';
import 'package:quranapp/features/adhkar/presentation/bloc/adhkar_state.dart';
import 'package:quranapp/l10n/app_localizations.dart';
import 'package:quranapp/core/widgets/error_state_widget.dart';
import 'package:share_plus/share_plus.dart';

class AdhkarListPage extends StatelessWidget {
  final String category;

  const AdhkarListPage({super.key, required this.category});

  String _getPageTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (category) {
      case 'morning':
        return l10n.tr('morningAdhkar');
      case 'evening':
        return l10n.tr('eveningAdhkar');
      case 'bedtime':
        return l10n.tr('bedtimeAdhkar');
      default:
        return l10n.tr('adhkarLabel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdhkarBloc>()..add(GetAdhkarByCategoryEvent(category)),
      child: _AdhkarListView(
        category: category,
        getPageTitle: () => _getPageTitle(context),
      ),
    );
  }
}

class _AdhkarListView extends StatefulWidget {
  final String category;
  final String Function() getPageTitle;

  const _AdhkarListView({required this.category, required this.getPageTitle});

  @override
  State<_AdhkarListView> createState() => _AdhkarListViewState();
}

class _AdhkarListViewState extends State<_AdhkarListView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.getPageTitle()),
        actions: [
          BlocBuilder<AdhkarBloc, AdhkarState>(
            builder: (context, state) {
              if (state is AdhkarLoaded && state.adhkarList.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _shareCurrentDhikr(state),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<AdhkarBloc, AdhkarState>(
        builder: (context, state) {
          if (state is AdhkarLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            );
          } else if (state is AdhkarError) {
            return ErrorStateWidget(
              failure: state.failure,
              onRetry: () {
                context.read<AdhkarBloc>().add(
                  GetAdhkarByCategoryEvent(widget.category),
                );
              },
            );
          } else if (state is AdhkarLoaded) {
            if (state.adhkarList.isEmpty) {
              return Center(child: Text(l10n.tr('adhkarUnavailable')));
            }
            return PageView.builder(
              controller: _pageController,
              itemCount: state.adhkarList.length,
              itemBuilder: (context, index) {
                final adhkar = state.adhkarList[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Main dhikr card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: theme.brightness == Brightness.dark
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                )
                              : null,
                        ),
                        child: Column(
                          children: [
                            // Arabic text
                            Text(
                              adhkar.zekr,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 2.0,
                                fontSize: 22,
                                fontFamily: 'Amiri',
                              ),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ),
                            // English translation
                            if (adhkar.englishText != null &&
                                adhkar.englishText!.trim().isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Divider(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                adhkar.englishText!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Count badge
                      if (adhkar.count > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryTeal.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.repeat_rounded,
                                size: 20,
                                color: AppTheme.primaryTeal,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.tr(
                                  'repeatCount',
                                  params: {'count': adhkar.count.toString()},
                                ),
                                style: TextStyle(
                                  color: AppTheme.primaryTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Reference
                      if (adhkar.reference != null &&
                          adhkar.reference!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          adhkar.reference!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.disabledColor,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Page indicator
                      Text(
                        '${index + 1} / ${state.adhkarList.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
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

  void _shareCurrentDhikr(AdhkarLoaded state) {
    final index = _pageController.hasClients
        ? (_pageController.page?.round() ?? 0)
        : 0;

    if (index >= 0 && index < state.adhkarList.length) {
      final adhkar = state.adhkarList[index];
      final text = '''${adhkar.zekr}

${adhkar.englishText != null && adhkar.englishText!.trim().isNotEmpty ? '${adhkar.englishText!}\n\n' : ''}${adhkar.count > 1 ? 'Repeat: ${adhkar.count} times\n' : ''}${adhkar.reference != null ? '${adhkar.reference}\n' : ''}- Shared via Quran App''';

      SharePlus.instance.share(ShareParams(text: text));
    }
  }
}
