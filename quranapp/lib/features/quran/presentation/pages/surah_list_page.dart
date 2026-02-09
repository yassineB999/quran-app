import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/core/widgets/error_state_widget.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_state.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class SurahListPage extends StatelessWidget {
  final bool openMushafOnTap;
  final String? title;

  const SurahListPage({super.key, this.openMushafOnTap = false, this.title});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuranBloc>()..add(GetAllSurahsEvent()),
      child: _SurahListView(openMushafOnTap: openMushafOnTap, title: title),
    );
  }
}

class _SurahListView extends StatefulWidget {
  final bool openMushafOnTap;
  final String? title;

  const _SurahListView({required this.openMushafOnTap, required this.title});

  @override
  State<_SurahListView> createState() => _SurahListViewState();
}

class _SurahListViewState extends State<_SurahListView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final pageTitle = widget.title ?? l10n.tr('quranTitle');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        actions: [
          IconButton(
            icon: Icon(
              Icons.auto_stories,
              color: theme.iconTheme.color ?? colorScheme.primary,
            ),
            tooltip: l10n.tr('bookModeTooltip'),
            onPressed: () => context.push('/read'),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: l10n.tr('searchSurahHint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: l10n.tr('clearSearch'),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<QuranBloc, QuranState>(
                builder: (context, state) {
                  if (state is QuranLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryTeal,
                      ),
                    );
                  }
                  if (state is QuranError) {
                    return ErrorStateWidget(
                      failure: state.failure,
                      onRetry: () {
                        context.read<QuranBloc>().add(GetAllSurahsEvent());
                      },
                    );
                  }
                  if (state is QuranListLoaded) {
                    final filtered = _filterSurahs(state.surahs, _query);
                    if (filtered.isEmpty) {
                      return _EmptyState(
                        title: l10n.tr('surahListEmptyTitle'),
                        subtitle: l10n.tr('surahListEmptySubtitle'),
                        onRetry: () {
                          context.read<QuranBloc>().add(GetAllSurahsEvent());
                        },
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<QuranBloc>().add(GetAllSurahsEvent());
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                        itemBuilder: (context, index) {
                          final surah = filtered[index];
                          return SurahListItem(
                            surah: surah,
                            openMushafOnTap: widget.openMushafOnTap,
                            onTap: () {
                              if (widget.openMushafOnTap) {
                                context.push('/mushaf/${surah.number}');
                              } else {
                                context.push('/quran/${surah.number}');
                              }
                            },
                            onLongPress: widget.openMushafOnTap
                                ? null
                                : () {
                                    context.push('/mushaf/${surah.number}');
                                  },
                            onReadTap: () {
                              context.push('/quran/${surah.number}');
                            },
                            onMushafTap: () {
                              context.push('/mushaf/${surah.number}');
                            },
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Surah> _filterSurahs(List<Surah> surahs, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return surahs;
    final lower = trimmed.toLowerCase();
    final number = int.tryParse(trimmed);
    return surahs.where((surah) {
      final name = surah.name.toLowerCase();
      final place = surah.revelationPlace.toLowerCase();
      final arabic = surah.arabicName;
      final matchesNumber = number != null && surah.number == number;
      return matchesNumber ||
          name.contains(lower) ||
          place.contains(lower) ||
          arabic.contains(trimmed);
    }).toList();
  }
}

String _localizeRevelationPlace(String value, AppLocalizations l10n) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'meccan' ||
      normalized == 'makkah' ||
      normalized == 'makki') {
    return l10n.tr('revelationPlaceMeccan');
  }
  if (normalized == 'medinan' ||
      normalized == 'madinah' ||
      normalized == 'madani') {
    return l10n.tr('revelationPlaceMedinan');
  }
  return value;
}

class SurahListItem extends StatelessWidget {
  final Surah surah;
  final bool openMushafOnTap;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onReadTap;
  final VoidCallback onMushafTap;

  const SurahListItem({
    super.key,
    required this.surah,
    required this.openMushafOnTap,
    required this.onTap,
    required this.onLongPress,
    required this.onReadTap,
    required this.onMushafTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final localizedPlace = _localizeRevelationPlace(
      surah.revelationPlace,
      l10n,
    );
    final subtitle = l10n.tr(
      'verseCountSubtitle',
      params: {
        'revelationPlace': localizedPlace,
        'count': '${surah.versesCount}',
      },
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${surah.number}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    surah.arabicName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.menu_book_outlined),
                        tooltip: l10n.tr('readSurah'),
                        color: openMushafOnTap
                            ? colorScheme.onSurface.withValues(alpha: 0.6)
                            : colorScheme.primary,
                        onPressed: onReadTap,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.auto_stories),
                        tooltip: l10n.tr('mushafRecitationTitle'),
                        color: openMushafOnTap
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                        onPressed: onMushafTap,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
