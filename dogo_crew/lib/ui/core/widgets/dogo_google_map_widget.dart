import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlong;

import '../../../../data/services/road_routing_service.dart';

/// DOGO Dark Mode map style JSON conforming to Google Maps Platform styling standards.
/// Uses deep obsidian background (#0D0F14 / #12151D) with subdued road networks
/// and high-contrast electric blue water/transit accents.
const String dogoDarkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#12151d"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8292aa"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#0d0f14"}]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#c7d2fe"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#4b5563"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#14231b"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#34d399"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#1f2637"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#161b27"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9ca3af"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#2d3748"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#1a202c"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#f9fafb"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#1e293b"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#60a5fa"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#0a0e17"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#3b82f6"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#0a0e17"}]
  }
]
''';

/// Native Google Maps SDK widget for the DOGO Platform.
///
/// ARCHITECTURAL PRINCIPLE:
/// Continuous driver tracking utilizes the device's native GPS hardware
/// and Supabase Realtime broadcast channels to update marker positions in memory.
/// NO Google Maps Directions or Routes API requests are triggered during continuous tracking.
/// Route polylines are requested ONCE on ride initiation and cached.
class DogoGoogleMapWidget extends StatefulWidget {
  final latlong.LatLng pickup;
  final latlong.LatLng dropoff;
  final latlong.LatLng? driverPosition;
  final double driverHeading;
  final String vehicleType; // 'taxi', 'keke', 'bike'
  final double height;
  final bool showControls;
  final bool isInteractive;
  final String? pickupTitle;
  final String? dropoffTitle;
  final void Function(gmaps.GoogleMapController)? onMapCreated;

  const DogoGoogleMapWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.driverPosition,
    this.driverHeading = 0.0,
    this.vehicleType = 'taxi',
    this.height = 280,
    this.showControls = true,
    this.isInteractive = true,
    this.pickupTitle,
    this.dropoffTitle,
    this.onMapCreated,
  });

  @override
  State<DogoGoogleMapWidget> createState() => _DogoGoogleMapWidgetState();
}

class _DogoGoogleMapWidgetState extends State<DogoGoogleMapWidget> {
  gmaps.GoogleMapController? _controller;
  List<latlong.LatLng> _roadPolylinePoints = [];
  List<latlong.LatLng> _driverApproachPoints = [];
  bool _isLoadingRoute = false;
  gmaps.BitmapDescriptor? _driverCustomIcon;

  // Cache to avoid re-generating vehicle icon bitmaps unnecessarily
  static final Map<String, gmaps.BitmapDescriptor> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _loadVehicleIcon();
    _fetchRoadRoute();
  }

  @override
  void didUpdateWidget(covariant DogoGoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If vehicle type changed, update icon
    if (widget.vehicleType != oldWidget.vehicleType) {
      _loadVehicleIcon();
    }

    // Only re-fetch route if pickup or destination changed
    if (widget.pickup != oldWidget.pickup || widget.dropoff != oldWidget.dropoff) {
      _fetchRoadRoute();
    } else if (widget.driverPosition != null &&
        oldWidget.driverPosition != widget.driverPosition) {
      // Driver position moved:
      // Note: We do NOT make Google Routes API calls on driver GPS ticks!
      // Only recalculate approach path if driver was previously null or moved significantly
      final oldPos = oldWidget.driverPosition;
      final newPos = widget.driverPosition!;
      final diff = (newPos.latitude - (oldPos?.latitude ?? 0)).abs() +
          (newPos.longitude - (oldPos?.longitude ?? 0)).abs();

      // If moved more than ~400 meters during initial pickup approach, update approach
      if (oldPos == null || (_driverApproachPoints.isNotEmpty && diff > 0.005)) {
        _fetchDriverApproachRoute();
      }
    }
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  /// Converts latlong2.LatLng to google_maps_flutter.LatLng
  gmaps.LatLng _toGmaps(latlong.LatLng point) {
    return gmaps.LatLng(point.latitude, point.longitude);
  }

  /// Generates a high-resolution circular vehicle avatar bitmap for the driver marker
  Future<void> _loadVehicleIcon() async {
    final type = widget.vehicleType.toLowerCase();
    if (_iconCache.containsKey(type)) {
      if (mounted) setState(() => _driverCustomIcon = _iconCache[type]);
      return;
    }

    try {
      final icon = await _createVehicleBitmap(type);
      _iconCache[type] = icon;
      if (mounted) {
        setState(() => _driverCustomIcon = icon);
      }
    } catch (_) {
      // Fallback to default azure hue marker
      _driverCustomIcon = gmaps.BitmapDescriptor.defaultMarkerWithHue(
        gmaps.BitmapDescriptor.hueAzure,
      );
    }
  }

  static Future<gmaps.BitmapDescriptor> _createVehicleBitmap(String vehicleType) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 110.0;
    const center = Offset(size / 2, size / 2);

    // 1. Outer Glow
    final glowPaint = Paint()
      ..color = const Color(0x662563EB)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, 44, glowPaint);

    // 2. Main Background Circle
    final bgPaint = Paint()..color = const Color(0xFF141722);
    canvas.drawCircle(center, 40, bgPaint);

    // 3. Electric Blue Border Ring
    final borderPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(center, 40, borderPaint);

    // 4. Directional Top Accent Indicator
    final accentPaint = Paint()..color = const Color(0xFF38BDF8);
    final arrowPath = Path()
      ..moveTo(center.dx - 8, center.dy - 34)
      ..lineTo(center.dx, center.dy - 44)
      ..lineTo(center.dx + 8, center.dy - 34)
      ..close();
    canvas.drawPath(arrowPath, accentPaint);

    // 5. Vehicle Emoji / Character
    String emoji;
    switch (vehicleType) {
      case 'keke':
      case 'tricycle':
        emoji = '🛺';
        break;
      case 'bike':
      case 'motorcycle':
        emoji = '🏍️';
        break;
      case 'taxi':
      default:
        emoji = '🚕';
        break;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 36),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 + 1),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return gmaps.BitmapDescriptor.bytes(bytes);
  }

  /// Calculates real road polylines once and caches in memory
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

      List<latlong.LatLng> approach = [];
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

        // Frame the route on initial load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitRouteBounds();
        });
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
    if (_controller == null) return;

    final points = <latlong.LatLng>[];
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

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat, minLng),
      northeast: gmaps.LatLng(maxLat, maxLng),
    );

    try {
      _controller?.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(bounds, 56.0),
      );
    } catch (_) {
      // In case viewport size not yet available, fallback to center
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      _controller?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(centerLat, centerLng), 13.5),
      );
    }
  }

  void _centerOnDriver() {
    final target = widget.driverPosition ?? widget.pickup;
    _controller?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(_toGmaps(target), 16.0),
    );
  }

  Set<gmaps.Marker> _buildMarkers() {
    final markers = <gmaps.Marker>{};
    final hasActiveTrip = widget.pickup != widget.dropoff;

    // 1. Pickup Marker (Green)
    if (hasActiveTrip) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: _toGmaps(widget.pickup),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
          infoWindow: gmaps.InfoWindow(
            title: widget.pickupTitle ?? 'Pickup Location',
            snippet: 'Trip Origin',
          ),
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }

    // 2. Dropoff Destination Marker (Red)
    if (hasActiveTrip) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('dropoff'),
          position: _toGmaps(widget.dropoff),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
          infoWindow: gmaps.InfoWindow(
            title: widget.dropoffTitle ?? 'Destination',
            snippet: 'Trip Dropoff',
          ),
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }

    // 3. Driver Live Marker (Smooth heading rotation & vehicle avatar)
    if (widget.driverPosition != null) {
      final icon = _driverCustomIcon ??
          gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure);

      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('driver'),
          position: _toGmaps(widget.driverPosition!),
          icon: icon,
          rotation: widget.driverHeading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          infoWindow: gmaps.InfoWindow(
            title: 'DOGO Captain (${widget.vehicleType.toUpperCase()})',
            snippet: 'Heading: ${widget.driverHeading.round()}°',
          ),
          zIndexInt: 10,
        ),
      );
    }

    return markers;
  }

  Set<gmaps.Polyline> _buildPolylines() {
    final polylines = <gmaps.Polyline>{};

    // 1. Driver Approach Polyline (Emerald Green)
    if (_driverApproachPoints.length >= 2) {
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('driver_approach'),
          points: _driverApproachPoints.map(_toGmaps).toList(),
          color: const Color(0xFF10B981),
          width: 5,
          jointType: gmaps.JointType.round,
          startCap: gmaps.Cap.roundCap,
          endCap: gmaps.Cap.roundCap,
          zIndex: 4,
        ),
      );
    }

    // 2. Main Trip Route Polyline (Electric Blue)
    final tripCoords = _roadPolylinePoints.isNotEmpty
        ? _roadPolylinePoints
        : (widget.pickup != widget.dropoff ? [widget.pickup, widget.dropoff] : <latlong.LatLng>[]);

    if (tripCoords.length >= 2) {
      // Glow border underlay
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('trip_route_glow'),
          points: tripCoords.map(_toGmaps).toList(),
          color: const Color(0x662563EB),
          width: 8,
          jointType: gmaps.JointType.round,
          startCap: gmaps.Cap.roundCap,
          endCap: gmaps.Cap.roundCap,
          zIndex: 2,
        ),
      );

      // Core crisp path
      polylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('trip_route_core'),
          points: tripCoords.map(_toGmaps).toList(),
          color: const Color(0xFF3B82F6),
          width: 5,
          jointType: gmaps.JointType.round,
          startCap: gmaps.Cap.roundCap,
          endCap: gmaps.Cap.roundCap,
          zIndex: 3,
        ),
      );
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final initialPos = widget.driverPosition ?? widget.pickup;

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
            gmaps.GoogleMap(
              initialCameraPosition: gmaps.CameraPosition(
                target: _toGmaps(initialPos),
                zoom: 14.5,
              ),
              style: dogoDarkMapStyle,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              rotateGesturesEnabled: widget.isInteractive,
              scrollGesturesEnabled: widget.isInteractive,
              tiltGesturesEnabled: widget.isInteractive,
              zoomGesturesEnabled: widget.isInteractive,
              onMapCreated: (controller) {
                _controller = controller;
                widget.onMapCreated?.call(controller);
                _fitRouteBounds();
              },
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

            // Top gradient overlay for contrast and sleek UI integration
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: IgnorePointer(
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
            ),

            // Floating Controls: Recenter on Driver/Pickup, Fit Bounds
            if (widget.showControls)
              Positioned(
                bottom: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFloatingButton(
                      icon: Icons.zoom_out_map_rounded,
                      tooltip: 'Fit route',
                      onTap: _fitRouteBounds,
                    ),
                    const SizedBox(height: 6),
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
      child: Tooltip(
        message: tooltip,
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
      ),
    );
  }
}
