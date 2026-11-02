import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/location_service.dart';
import '../../../core/widgets/osm_map_widget.dart';
import '../view_models/driver_view_model.dart';

class DriverMapWidget extends StatelessWidget {
  final DriverSession session;
  final DriverRideRequest request;

  const DriverMapWidget({
    super.key,
    required this.session,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final driverVm = context.watch<DriverViewModel>();
    final isTripActive = session == DriverSession.request ||
        session == DriverSession.toPickup ||
        session == DriverSession.atPickup ||
        session == DriverSession.onTrip ||
        session == DriverSession.complete;

    final pickup = LocationService.getCoordinates(request.pickupName);
    final dropoff = LocationService.getCoordinates(request.dropoffName);

    final centerPos = driverVm.currentDriverGps ?? const LatLng(6.5898, 3.3556);

    // Active driver position
    final driverPos = driverVm.currentDriverGps ??
        (session == DriverSession.toPickup
            ? const LatLng(6.5898, 3.3556)
            : (session == DriverSession.onTrip ? pickup : centerPos));

    return OsmMapWidget(
      height: double.infinity,
      pickup: isTripActive ? pickup : centerPos,
      dropoff: isTripActive ? dropoff : centerPos,
      driverPosition: driverPos,
      driverHeading: driverVm.currentDriverHeading,
      vehicleType: 'taxi',
      showControls: true,
      isInteractive: true,
    );
  }
}
