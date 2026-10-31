import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../data/services/road_routing_service.dart';

class OsmMapWidget extends StatefulWidget {
  final LatLng pickup;
  final LatLng dropoff;
  final LatLng? driverPosition;
  final double driverHeading;
  final String vehicleType; // 'taxi', 'keke', 'bike'
  final double height;
  final bool showControls;
  final bool isInteractive;

  const OsmMapWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.driverPosition,
    this.driverHeading = 0.0,
    this.vehicleType = 'taxi',
    this.height = 280,
    this.showControls = true,
    this.isInteractive = true,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseAnimCtrl;

  List<LatLng> _roadPolylinePoints = [];
  List<LatLng> _driverApproachPoints = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.driverPosition != null) {
        _mapController.move(widget.driverPosition!, 15.5);
      }
      _fetchRoadRoute();
    });
  }

  @override
  void didUpdateWidget(covariant OsmMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pickup != oldWidget.pickup || widget.dropoff != oldWidget.dropoff) {
      _fetchRoadRoute();
    } else if (widget.driverPosition != null &&
        oldWidget.driverPosition != widget.driverPosition) {
      final oldPos = oldWidget.driverPosition;
      final newPos = widget.driverPosition!;
      final diff = (newPos.latitude - (oldPos?.latitude ?? 0)).abs() +
          (newPos.longitude - (oldPos?.longitude ?? 0)).abs();
      if (diff > 0.004) {
        _fetchDriverApproachRoute();
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRoadRoute() async {
    if (widget.pickup == widget.dropoff) {
      if (mounted) {
        setState(() {
          _roadPolylinePoints = [];
          _driverApproachPoints = [];
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoadingRoute = true);

    try {
      final tripRoute = await RoadRoutingService.getDrivingRoute(
        widget.pickup,
        widget.dropoff,
      );

      List<LatLng> approach = [];
      if (widget.driverPosition != null &&
          widget.driverPosition != widget.pickup &&
          widget.driverPosition != widget.dropoff) {
        final approachRoute = await RoadRoutingService.getDrivingRoute(
          widget.driverPosition!,
          widget.pickup,
        );
        approach = approachRoute.coordinates;
      }

      if (mounted) {
        setState(() {
          _roadPolylinePoints = tripRoute.coordinates;
          _driverApproachPoints = approach;
          _isLoadingRoute = false;
        });

        // Frame the route on load
        _fitRouteBounds();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _fetchDriverApproachRoute() async {
    if (widget.driverPosition == null || widget.pickup == widget.dropoff) return;
    try {
      final approachRoute = await RoadRoutingService.getDrivingRoute(
        widget.driverPosition!,
        widget.pickup,
      );
      if (mounted) {
        setState(() {
          _driverApproachPoints = approachRoute.coordinates;
        });
      }
    } catch (_) {}
  }

  void _fitRouteBounds() {
    final points = <LatLng>[];
    if (_roadPolylinePoints.isNotEmpty) {
      points.addAll(_roadPolylinePoints);
    } else {
      points.add(widget.pickup);
      points.add(widget.dropoff);
    }
    if (_driverApproachPoints.isNotEmpty) {
      points.addAll(_driverApproachPoints);
    } else if (widget.driverPosition != null) {
      points.add(widget.driverPosition!);
    }

    if (points.isEmpty) return;

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
        ),
      );
    } catch (_) {}
  }

  void _centerOnDriver() {
    if (widget.driverPosition != null) {
      _mapController.move(widget.driverPosition!, 15.0);
    } else {
      _mapController.move(widget.pickup, 14.5);
    }
  }

  String _getVehicleEmoji() {
    switch (widget.vehicleType.toLowerCase()) {
      case 'keke':
      case 'tricycle':
        return '🛺';
      case 'bike':
        return '🏍️';
      case 'taxi':
      default:
        return '🚕';
    }
  }

  List<LatLng> _buildRoutePoints() {
    if (widget.pickup == widget.dropoff) return [];
    final pts = <LatLng>[];
    if (widget.driverPosition != null) {
      pts.add(widget.driverPosition!);
    }
    pts.add(widget.pickup);
    pts.add(widget.dropoff);
    return pts;
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = widget.driverPosition ?? widget.pickup;
    final activeTripPoints = _roadPolylinePoints.isNotEmpty
        ? _roadPolylinePoints
        : _buildRoutePoints();
    final hasActiveTrip = widget.pickup != widget.dropoff;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: widget.height == double.infinity ? null : widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x22FFFFFF), width: 1),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 13.5,
                minZoom: 4,
                maxZoom: 18,
                interactionOptions: InteractionOptions(
                  flags: widget.isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
              ),
              children: [
                // 1. Official OpenStreetMap Tiles with Dark Mode Color Filter (100% Free, No API Key Required)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dogo.crew',
                  maxZoom: 19,
                  tileBuilder: darkModeTileBuilder,
                ),

                // 2. Active Road Polylines (Real Street Geometries)
                PolylineLayer(
                  polylines: [
                    // Driver Approach Route (Green)
                    if (_driverApproachPoints.length >= 2) ...[
                      Polyline(
                        points: _driverApproachPoints,
                        strokeWidth: 6.5,
                        color: const Color(0x6610B981),
                      ),
                      Polyline(
                        points: _driverApproachPoints,
                        strokeWidth: 3.5,
                        color: const Color(0xFF10B981),
                      ),
                    ],

                    // Main Trip Route (Electric Blue)
                    if (activeTripPoints.length >= 2) ...[
                      Polyline(
                        points: activeTripPoints,
                        strokeWidth: 7.0,
                        color: const Color(0x662563EB),
                      ),
                      Polyline(
                        points: activeTripPoints,
                        strokeWidth: 4.0,
                        color: const Color(0xFF3B82F6),
                      ),
                    ],
                  ],
                ),

                // 3. Markers: Pickup, Dropoff, and Live Driver
                MarkerLayer(
                  markers: [
                    // Pickup Point Marker (Green with pulse)
                    if (hasActiveTrip)
                      Marker(
                        point: widget.pickup,
                        width: 44,
                        height: 44,
                        child: AnimatedBuilder(
                          animation: _pulseAnimCtrl,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 32 + (12 * _pulseAnimCtrl.value),
                                  height: 32 + (12 * _pulseAnimCtrl.value),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color.fromRGBO(16, 185, 129, (1 - _pulseAnimCtrl.value) * 0.45),
                                  ),
                                ),
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: const Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.white),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    // Dropoff Destination Marker (Red Pin)
                    if (hasActiveTrip)
                      Marker(
                        point: widget.dropoff,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.location_on_rounded, size: 18, color: Colors.white),
                        ),
                      ),

                    // Driver Live Marker (Vehicle Avatar + Heading Arrow)
                    if (widget.driverPosition != null)
                      Marker(
                        point: widget.driverPosition!,
                        width: 52,
                        height: 52,
                        child: Transform.rotate(
                          angle: (widget.driverHeading * math.pi) / 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141722),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF60A5FA), width: 2),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x802563EB),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _getVehicleEmoji(),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            if (_isLoadingRoute)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),

            // Top gradient overlay for contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC0D0F14), Colors.transparent],
                  ),
                ),
              ),
            ),

            // Floating Controls: Recenter, Fit Bounds, Zoom
            if (widget.showControls)
              Positioned(
                bottom: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fit Route Button
                    _buildFloatingButton(
                      icon: Icons.zoom_out_map_rounded,
                      tooltip: 'Fit route',
                      onTap: _fitRouteBounds,
                    ),
                    const SizedBox(height: 6),
                    // Recenter on Driver/Pickup Button
                    _buildFloatingButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Center on vehicle',
                      onTap: _centerOnDriver,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xCC141722),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33FFFFFF)),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
