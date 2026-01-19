import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_event.dart';
import 'package:quranapp/features/quran/presentation/bloc/quran_state.dart';

class SurahListPage extends StatelessWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme context
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => sl<QuranBloc>()..add(GetAllSurahsEvent()),
      child: Scaffold(
        // Use theme generic background for correct Light/Dark support
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Quran',
            style:
                theme.appBarTheme.titleTextStyle ??
                TextStyle(
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
              tooltip: 'Book Mode',
              onPressed: () => context.push('/read'),
            ),
          ],
        ),
        body: BlocBuilder<QuranBloc, QuranState>(
          builder: (context, state) {
            if (state is QuranLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              );
            } else if (state is QuranError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            } else if (state is QuranListLoaded) {
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: state.surahs.length,
                separatorBuilder: (context, index) =>
                    Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
                itemBuilder: (context, index) {
                  final surah = state.surahs[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        // Gold/Teal implementation based on design
                        color: isDark
                            ? AppTheme.primaryTeal.withValues(alpha: 0.2)
                            : AppTheme.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Rounded box instead of circle (modern)
                        border: Border.all(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${surah.number}',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      surah.name, // e.g. Al-Fatiha
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      '${surah.revelationPlace} • ${surah.versesCount} verses',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    trailing: Text(
                      surah.arabicName,
                      style: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontSize: 20,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      context.push('/quran/${surah.number}');
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
