import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class AdhkarCategoriesPage extends StatelessWidget {
  const AdhkarCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.tr('adhkarCategories'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildCategoryTile(
              context: context,
              icon: Icons.wb_sunny_rounded,
              title: l10n.tr('morningAdhkar'),
              subtitle: l10n.tr('morningAdhkarSubtitle'),
              category: 'morning',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildCategoryTile(
              context: context,
              icon: Icons.nightlight_round,
              title: l10n.tr('eveningAdhkar'),
              subtitle: l10n.tr('eveningAdhkarSubtitle'),
              category: 'evening',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildCategoryTile(
              context: context,
              icon: Icons.bedtime_rounded,
              title: l10n.tr('bedtimeAdhkar'),
              subtitle: l10n.tr('bedtimeAdhkarSubtitle'),
              category: 'bedtime',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String category,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/adhkar/$category'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryTeal, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.white54 : Colors.black26,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
