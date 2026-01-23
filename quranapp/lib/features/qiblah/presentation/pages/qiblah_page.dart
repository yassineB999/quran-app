import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:quranapp/config/theme/app_theme.dart';
import 'package:quranapp/core/constants/app_constants.dart';
import 'package:quranapp/core/di/injection_container.dart';
import 'package:quranapp/features/qiblah/domain/entities/nearby_mosque.dart';
import 'package:quranapp/features/qiblah/domain/entities/user_location.dart';
import 'package:quranapp/features/qiblah/domain/usecases/get_route_points.dart';
import 'package:quranapp/features/qiblah/presentation/bloc/nearby_mosques_bloc.dart';
import 'package:quranapp/features/qiblah/presentation/bloc/qiblah_bloc.dart';
import 'package:quranapp/features/qiblah/presentation/bloc/qiblah_state.dart';
import 'package:quranapp/features/qiblah/presentation/widgets/compass_widget.dart';
import 'package:quranapp/l10n/app_localizations.dart';

class QiblahPage extends StatelessWidget {
  const QiblahPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<QiblahBloc>()..add(InitQiblahEvent())),
        BlocProvider(
          create: (_) =>
              sl<NearbyMosquesBloc>()..add(const LoadNearbyMosquesEvent()),
        ),
      ],
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
        title: const SizedBox.shrink(),
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
          BlocConsumer<NearbyMosquesBloc, NearbyMosquesState>(
            listener: (context, state) {
              if (state is NearbyMosquesLoaded && state.errorMessage != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
                context.read<NearbyMosquesBloc>().add(
                  const NearbyMosquesErrorShown(),
                );
              }
            },
            builder: (context, state) {
              if (state is NearbyMosquesLoading ||
                  state is NearbyMosquesInitial) {
                return Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                );
              }
              if (state is NearbyMosquesPermissionDenied) {
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
                          l10n.tr('locationPermissionRequired'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {
                            context.read<NearbyMosquesBloc>().add(
                              const LoadNearbyMosquesEvent(),
                            );
                          },
                          child: Text(l10n.tr('allowLocationAccess')),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state is NearbyMosquesError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
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
                            context.read<NearbyMosquesBloc>().add(
                              const LoadNearbyMosquesEvent(),
                            );
                          },
                          child: Text(l10n.tr('retry')),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (state is NearbyMosquesLoaded) {
                return _NearbyMosquesView(isDark: isDark, state: state);
              }
              return const SizedBox.shrink();
            },
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

                    const SizedBox(height: 24),
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
}

class _NearbyMosquesView extends StatefulWidget {
  final bool isDark;
  final NearbyMosquesLoaded state;

  const _NearbyMosquesView({required this.isDark, required this.state});

  @override
  State<_NearbyMosquesView> createState() => _NearbyMosquesViewState();
}

class _NearbyMosquesViewState extends State<_NearbyMosquesView> {
  late final MapController _mapController;
  NearbyMosque? _selectedMosque;
  List<LatLng> _routePoints = [];
  bool _routeLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToAllMosques();
    });
  }

  @override
  void didUpdateWidget(covariant _NearbyMosquesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.mosques != widget.state.mosques &&
        _selectedMosque == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitToAllMosques();
      });
    }
    if (oldWidget.state.location != widget.state.location &&
        _selectedMosque != null &&
        !_routeLoading) {
      _loadRoute(_selectedMosque!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
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
                  TileLayer(urlTemplate: AppConstants.openStreetMapTileUrl),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(points: _routePoints, strokeWidth: 4),
                      ],
                    ),
                  MarkerLayer(markers: _buildMarkers()),
                  RichAttributionWidget(
                    attributions: const [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                                  Divider(height: 24, color: Colors.grey[300]),
                              itemBuilder: (context, index) {
                                final mosque = state.mosques[index];
                                final isSelected =
                                    _selectedMosque?.id == mosque.id;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  selected: isSelected,
                                  onTap: () => _onMosqueTap(mosque),
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

  Future<void> _onMosqueTap(NearbyMosque mosque) async {
    if (_selectedMosque?.id == mosque.id) {
      _clearSelection();
      return;
    }
    setState(() {
      _selectedMosque = mosque;
      _routePoints = [];
      _routeLoading = true;
    });
    _fitToSelected(mosque);
    await _loadRoute(mosque);
  }

  Future<void> _loadRoute(NearbyMosque mosque) async {
    if (!mounted) return;
    setState(() {
      _routeLoading = true;
      _routePoints = [];
    });
    final origin = UserLocation(
      latitude: widget.state.location.latitude,
      longitude: widget.state.location.longitude,
    );
    final destination = UserLocation(
      latitude: mosque.latitude,
      longitude: mosque.longitude,
    );
    final result = await sl<GetRoutePoints>()(
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
    _fitToAllMosques();
  }

  void _fitToAllMosques() {
    final points = <LatLng>[
      LatLng(widget.state.location.latitude, widget.state.location.longitude),
      ...widget.state.mosques.map(
        (mosque) => LatLng(mosque.latitude, mosque.longitude),
      ),
    ];
    if (points.isEmpty) {
      return;
    }
    if (points.length < 2) {
      _mapController.move(points.first, 14);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  void _fitToSelected(NearbyMosque mosque) {
    final bounds = LatLngBounds.fromPoints([
      LatLng(widget.state.location.latitude, widget.state.location.longitude),
      LatLng(mosque.latitude, mosque.longitude),
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  String _displayName(NearbyMosque mosque, AppLocalizations l10n) {
    if (mosque.name.trim().isNotEmpty) {
      return mosque.name;
    }
    if (mosque.city.trim().isNotEmpty) {
      return mosque.city;
    }
    return l10n.tr('mosqueUnnamed');
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[
      Marker(
        point: LatLng(
          widget.state.location.latitude,
          widget.state.location.longitude,
        ),
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
    for (final mosque in widget.state.mosques) {
      final isSelected = _selectedMosque?.id == mosque.id;
      markers.add(
        Marker(
          point: LatLng(mosque.latitude, mosque.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMosqueTap(mosque),
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
