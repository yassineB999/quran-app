import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/qiblah/presentation/bloc/qiblah_bloc.dart';
import 'package:quranapp/features/qiblah/presentation/bloc/qiblah_state.dart';
import 'package:quranapp/features/qiblah/presentation/widgets/compass_widget.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class QiblahPage extends StatelessWidget {
  const QiblahPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QiblahBloc>()..add(InitQiblahEvent()),
      child: const _QiblahView(),
    );
  }
}

class _QiblahView extends StatefulWidget {
  const _QiblahView();

  @override
  State<_QiblahView> createState() => _QiblahViewState();
}

class _QiblahViewState extends State<_QiblahView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 1,
    ); // Compass default
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.tr('qiblahTitle')),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryTeal,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: l10n.tr('mapTab')),
            Tab(text: l10n.tr('compassTab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Map Tab (Placeholder)
          Center(
            child: Text(
              l10n.tr('mapViewComingSoon'),
              style: theme.textTheme.bodyLarge,
            ),
          ),

          // Compass Tab
          BlocBuilder<QiblahBloc, QiblahState>(
            builder: (context, state) {
              if (state is QiblahLoading) {
                return Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                );
              } else if (state is QiblahError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_disabled,
                          size: 48,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {
                            context.read<QiblahBloc>().add(InitQiblahEvent());
                          },
                          child: Text(l10n.tr('allowLocationAccess')),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (state is QiblahLoaded) {
                final data = state.direction;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(height: 20),
                    // Compass UI
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: CompassWidget(
                          heading: data.heading,
                          qiblahBearing: data.qiblahBearing,
                        ),
                      ),
                    ),

                    // Info Panel
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              l10n.tr('qiblahFromNorthLabel'),
                              '${data.qiblahBearing.toStringAsFixed(1)}°',
                              isDark,
                            ),
                            const Divider(height: 32),
                            _buildInfoRow(
                              l10n.tr('distanceLabel'),
                              l10n.tr(
                                'distanceValue',
                                params: {
                                  'distance':
                                      data.distanceInKm.toStringAsFixed(1),
                                },
                              ),
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            letterSpacing: 1.0,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
