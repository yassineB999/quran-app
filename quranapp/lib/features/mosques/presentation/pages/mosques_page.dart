import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/constants/app_constants.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/core/location/domain/entities/user_location.dart';
import 'package:quranapp/features/mosques/domain/entities/mosque.dart';
import 'package:quranapp/features/mosques/domain/usecases/get_route_to_mosque.dart';
import 'package:quranapp/features/mosques/presentation/bloc/mosque_bloc.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class MosquesPage extends StatelessWidget {
  const MosquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MosqueBloc>()..add(const LoadMosquesEvent()),
      child: const _MosquesView(),
    );
  }
}

class _MosquesView extends StatefulWidget {
  const _MosquesView();

  @override
  State<_MosquesView> createState() => _MosquesViewState();
}

class _MosquesViewState extends State<_MosquesView> {
  late final MapController _mapController;
  Mosque? _selectedMosque;
  List<LatLng> _routePoints = [];
  bool _routeLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tr('nearbyMosquesLabel'))),
      body: BlocConsumer<MosqueBloc, MosqueState>(
        listener: (context, state) {
          if (state is MosqueLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            context.read<MosqueBloc>().add(const MosqueErrorShown());
          }
        },
        builder: (context, state) {
          if (state is MosqueLoading || state is MosqueInitial) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            );
          }
          if (state is MosquePermissionDenied) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_disabled,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.tr('locationPermissionRequired'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        context.read<MosqueBloc>().add(
                          const LoadMosquesEvent(),
                        );
                      },
                      child: Text(l10n.tr('allowLocationAccess')),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is MosqueError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
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
                        context.read<MosqueBloc>().add(
                          const LoadMosquesEvent(),
                        );
                      },
                      child: Text(l10n.tr('retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is MosqueLoaded) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final mapHeight = constraints.maxHeight * 0.5;
                return Column(
                  children: [
                    SizedBox(
                      height: mapHeight,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(
                            state.location.latitude,
                            state.location.longitude,
                          ),
                          initialZoom: 14,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: AppConstants.openStreetMapTileUrl,
                          ),
                          if (_routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(points: _routePoints, strokeWidth: 4),
                              ],
                            ),
                          MarkerLayer(markers: _buildMarkers(state, isDark)),
                          RichAttributionWidget(
                            attributions: const [
                              TextSourceAttribution(
                                '© OpenStreetMap contributors',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        child: state.mosques.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.tr('nearbyMosquesEmpty'),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              )
                            : Column(
                                children: [
                                  if (state.isRefreshing)
                                    const LinearProgressIndicator(minHeight: 2),
                                  if (_selectedMosque != null)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        8,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              l10n.tr(
                                                'routeToMosque',
                                                params: {
                                                  'name': _displayName(
                                                    _selectedMosque!,
                                                    l10n,
                                                  ),
                                                },
                                              ),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleSmall,
                                            ),
                                          ),
                                          if (_routeLoading)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          TextButton(
                                            onPressed: _clearSelection,
                                            child: Text(l10n.tr('clearRoute')),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      itemCount: state.mosques.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                            height: 24,
                                            color: Colors.grey[300],
                                          ),
                                      itemBuilder: (context, index) {
                                        final mosque = state.mosques[index];
                                        final isSelected =
                                            _selectedMosque?.id == mosque.id;
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          selected: isSelected,
                                          onTap: () =>
                                              _onMosqueTap(mosque, state),
                                          title: Text(
                                            mosque.name.isEmpty
                                                ? l10n.tr('mosqueUnnamed')
                                                : mosque.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          subtitle: Text(
                                            mosque.city.isEmpty
                                                ? l10n.tr('mosqueUnnamed')
                                                : mosque.city,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                          trailing: Text(
                                            l10n.tr(
                                              'distanceAway',
                                              params: {
                                                'distance': mosque.distanceKm
                                                    .toStringAsFixed(1),
                                              },
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _onMosqueTap(Mosque mosque, MosqueLoaded state) async {
    if (_selectedMosque?.id == mosque.id) {
      _clearSelection();
      return;
    }
    setState(() {
      _selectedMosque = mosque;
      _routePoints = [];
      _routeLoading = true;
    });
    _fitToSelected(mosque, state);
    await _loadRoute(mosque, state);
  }

  Future<void> _loadRoute(Mosque mosque, MosqueLoaded state) async {
    if (!mounted) return;
    setState(() {
      _routeLoading = true;
      _routePoints = [];
    });
    final origin = UserLocation(
      latitude: state.location.latitude,
      longitude: state.location.longitude,
    );
    final destination = UserLocation(
      latitude: mosque.latitude,
      longitude: mosque.longitude,
    );
    final result = await sl<GetRouteToMosque>()(
      origin: origin,
      destination: destination,
    );

    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _routeLoading = false;
          _routePoints = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message.isNotEmpty
                  ? failure.message
                  : AppLocalizations.of(context).tr('routeFailed'),
            ),
          ),
        );
      },
      (points) {
        final routePoints = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(growable: false);
        if (!mounted) return;
        setState(() {
          _routePoints = routePoints;
          _routeLoading = false;
        });
        if (routePoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(routePoints);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
          );
        }
      },
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedMosque = null;
      _routePoints = [];
      _routeLoading = false;
    });
  }

  void _fitToSelected(Mosque mosque, MosqueLoaded state) {
    final bounds = LatLngBounds.fromPoints([
      LatLng(state.location.latitude, state.location.longitude),
      LatLng(mosque.latitude, mosque.longitude),
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  String _displayName(Mosque mosque, AppLocalizations l10n) {
    if (mosque.name.trim().isNotEmpty) {
      return mosque.name;
    }
    if (mosque.city.trim().isNotEmpty) {
      return mosque.city;
    }
    return l10n.tr('mosqueUnnamed');
  }

  List<Marker> _buildMarkers(MosqueLoaded state, bool isDark) {
    final markers = <Marker>[
      Marker(
        point: LatLng(state.location.latitude, state.location.longitude),
        width: 40,
        height: 40,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.my_location, color: Colors.white, size: 20),
        ),
      ),
    ];
    for (final mosque in state.mosques) {
      final isSelected = _selectedMosque?.id == mosque.id;
      markers.add(
        Marker(
          point: LatLng(mosque.latitude, mosque.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMosqueTap(mosque, state),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepOrange : Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.mosque, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }
    return markers;
  }
}
