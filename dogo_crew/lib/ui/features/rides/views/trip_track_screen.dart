import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/services/driver_tracking_service.dart';
import '../../../../data/services/trip_chat_service.dart';
import '../../../core/widgets/osm_map_widget.dart';
import '../view_models/rides_view_model.dart';
import '../widgets/cancel_ride_modal.dart';
import '../widgets/driver_chat_modal.dart';
import '../widgets/receipt_dialog_widget.dart';
import '../widgets/rides_header_widget.dart';

class TripTrackScreen extends StatefulWidget {
  final String tripCode;

  const TripTrackScreen({super.key, required this.tripCode});

  @override
  State<TripTrackScreen> createState() => _TripTrackScreenState();
}

class _TripTrackScreenState extends State<TripTrackScreen> {
  final DriverTrackingService _trackingService = DriverTrackingService();
  StreamSubscription<DriverPosition>? _driverLocationSub;
  LatLng? _liveDriverPosition;
  double _liveDriverHeading = 0.0;
  int _riderRating = 5;
  bool _hasRated = false;
  int? _tippedAmount;
  bool _isTipping = false;
  bool _isLoadingTimedOut = false;
  Timer? _loadingTimeoutTimer;
  String? _previousStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RidesViewModel>().selectRideByCode(widget.tripCode);
    });

    _loadingTimeoutTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isLoadingTimedOut = true;
        });
      }
    });

    _driverLocationSub = _trackingService.subscribeToDriverLocation(widget.tripCode).listen((pos) {
      if (mounted) {
        setState(() {
          _liveDriverPosition = pos.point;
          _liveDriverHeading = pos.heading;
        });
      }
    });
  }

  @override
  void dispose() {
    _loadingTimeoutTimer?.cancel();
    _driverLocationSub?.cancel();
    _trackingService.dispose();
    super.dispose();
  }

  static const List<String> _stages = [
    'pending',
    'accepted',
    'to_pickup',
    'at_pickup',
    'on_trip',
    'completed',
  ];

  static const List<String> _stageLabels = [
    'Finding Driver',
    'Driver Confirmed',
    'Driver En Route',
    'Driver at Pickup',
    'Trip in Progress',
    'Completed',
  ];

  static int _getStageIndex(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'accepted':
      case 'confirmed':
        return 1;
      case 'to_pickup':
      case 'picked_up':
        return 2;
      case 'at_pickup':
        return 3;
      case 'on_trip':
      case 'in_transit':
      case 'arriving':
        return 4;
      case 'completed':
      case 'delivered':
        return 5;
      default:
        return 0;
    }
  }

  static String _getStatusPillLabel(String status) {
    if (status == 'cancelled') return 'Cancelled';
    switch (status) {
      case 'pending':
        return 'Finding Driver';
      case 'accepted':
      case 'confirmed':
        return 'Driver Confirmed';
      case 'to_pickup':
      case 'picked_up':
        return 'Driver En Route';
      case 'at_pickup':
        return 'Driver at Pickup';
      case 'on_trip':
      case 'in_transit':
      case 'arriving':
        return 'Trip in Progress';
      case 'completed':
      case 'delivered':
        return 'Completed';
      default:
        return 'Active';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RidesViewModel>();
    final ride = vm.selectedRide ?? vm.ridesRepo.getRide(widget.tripCode);

    if (ride == null) {
      if (!_isLoadingTimedOut) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0F14),
          body: Column(
            children: [
              const RidesHeaderWidget(activeRoute: '/rides'),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connecting to live trip ${widget.tripCode}...',
                        style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFF0D0F14),
        body: Column(
          children: [
            const RidesHeaderWidget(activeRoute: '/rides'),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
                    const SizedBox(height: 12),
                    Text(
                      'Trip not found',
                      style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We could not find ${widget.tripCode}.',
                      style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => context.go('/rides'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Back to rides'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isCancelled = ride.status == 'cancelled';
    if (_previousStatus != null && _previousStatus != ride.status) {
      if (ride.status == 'at_pickup') {
        try {
          HapticFeedback.vibrate();
        } catch (_) {}
      } else if (ride.status == 'completed') {
        try {
          HapticFeedback.heavyImpact();
        } catch (_) {}
      } else if (ride.status == 'accepted' || ride.status == 'confirmed' || ride.status == 'to_pickup') {
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}
      }
    }
    _previousStatus = ride.status;
    final validStageIdx = _getStageIndex(ride.status);
    final progress = isCancelled ? 0.0 : (validStageIdx / (_stages.length - 1));
    final formattedPrice = '₦${NumberFormat('#,###').format(ride.price)}';

    final pickupCoord = LatLng(ride.pickupLat, ride.pickupLng);
    final dropoffCoord = LatLng(ride.dropoffLat, ride.dropoffLng);

    LatLng? currentDriverPos = _liveDriverPosition;
    if (currentDriverPos == null && !isCancelled && ride.status != 'pending') {
      final routePts = DriverTrackingService.generateRoutePoints(pickupCoord, dropoffCoord);
      final targetIdx = (progress * (routePts.length - 1)).round().clamp(0, routePts.length - 1);
      currentDriverPos = routePts[targetIdx];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Column(
        children: [
          const RidesHeaderWidget(activeRoute: '/rides'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back to all shipments/trips
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.go(ride.isCourier ? '/rides/my-trips' : '/rides'),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF9CA3AF)),
                          label: Text(
                            ride.isCourier ? 'All shipments' : 'Back to rides',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 1. Top Map Card with Trip Code & Status Pill
                      Stack(
                        children: [
                          OsmMapWidget(
                            height: 270,
                            pickup: pickupCoord,
                            dropoff: dropoffCoord,
                            driverPosition: currentDriverPos,
                            driverHeading: _liveDriverHeading,
                            vehicleType: ride.vehicleId,
                          ),
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ride.code,
                                        style: GoogleFonts.sora(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${ride.pickup} → ${ride.dropoff}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFFD1D5DB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isCancelled ? const Color(0x2EEF4444) : const Color(0x2E10B981),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isCancelled ? const Color(0x66EF4444) : const Color(0x6610B981)),
                                  ),
                                  child: Text(
                                    _getStatusPillLabel(ride.status),
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isCancelled ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Driver At Pickup Arrival Alert Banner
                      if (ride.status == 'at_pickup') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0x2E10B981), Color(0x1F0D5C3E)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x8010B981), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0x3310B981),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.car_rental_rounded, color: Color(0xFF10B981), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Driver has arrived outside!',
                                      style: GoogleFonts.sora(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Please meet your driver and share your 4-digit PIN: ${ride.pin}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Trip Completed Celebratory Banner, Real-time Settlement & Tip Sheet
                      if (ride.status == 'completed' || ride.status == 'delivered') ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF16241D), Color(0xFF121824)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x6610B981), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0x3310B981),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trip completed!',
                                          style: GoogleFonts.sora(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'You have arrived at your destination safely.',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Real-Time Fare Settlement & Wallet Deduction Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F121B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0x3310B981)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF10B981)),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Fare Settlement',
                                              style: GoogleFonts.manrope(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0x3310B981),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Settled ✓',
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Paid',
                                          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
                                        ),
                                        Text(
                                          formattedPrice,
                                          style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Payment Method',
                                          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                                        ),
                                        Text(
                                          ride.payment.toLowerCase().contains('wallet')
                                              ? 'DOGO Wallet (₦${NumberFormat('#,###').format(ride.price)} deducted)'
                                              : ride.payment,
                                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF60A5FA)),
                                        ),
                                      ],
                                    ),
                                    if (ride.payment.toLowerCase().contains('wallet')) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Remaining Balance',
                                            style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                                          ),
                                          Text(
                                            vm.formattedWalletBalance,
                                            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF10B981)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Quick Tip Driver Chips (Real-time Broadcast)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F121B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0x1FFFFFFF)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Tip Captain ${ride.driverName.isNotEmpty ? ride.driverName.split(" ").first : "Driver"}',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (_tippedAmount != null)
                                          Text(
                                            'Tipped ₦${NumberFormat('#,###').format(_tippedAmount!)} 🎉',
                                            style: GoogleFonts.manrope(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (_tippedAmount == null) ...[
                                      Text(
                                        'Instant wallet deduction · Sent straight to driver in real-time',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [200, 500, 1000, 2000].map((tipAmt) {
                                          return Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 3),
                                              child: ElevatedButton(
                                                onPressed: _isTipping
                                                    ? null
                                                    : () async {
                                                        final messenger = ScaffoldMessenger.of(context);
                                                        setState(() => _isTipping = true);
                                                        final success = await vm.tipDriver(amount: tipAmt);
                                                        if (!mounted) return;
                                                        setState(() {
                                                          _isTipping = false;
                                                          if (success) _tippedAmount = tipAmt;
                                                        });
                                                        if (success) {
                                                          try {
                                                            HapticFeedback.heavyImpact();
                                                          } catch (_) {}
                                                          messenger.showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '₦${NumberFormat('#,###').format(tipAmt)} tip sent to ${ride.driverName.isNotEmpty ? ride.driverName : "Captain"}!',
                                                              ),
                                                              backgroundColor: const Color(0xFF10B981),
                                                              behavior: SnackBarBehavior.floating,
                                                            ),
                                                          );
                                                        } else {
                                                          messenger.showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Insufficient wallet balance to tip.'),
                                                              backgroundColor: Color(0xFFEF4444),
                                                              behavior: SnackBarBehavior.floating,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1F2433),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(10),
                                                    side: const BorderSide(color: Color(0x33FFFFFF)),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: Text(
                                                  '+₦$tipAmt',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ] else
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0x1A10B981),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Thank you! Your ₦${NumberFormat('#,###').format(_tippedAmount!)} tip was credited to ${ride.driverName.isNotEmpty ? ride.driverName : "Captain"}.',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF10B981),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 5-Star Rating Row
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F121B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0x1FFFFFFF)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _hasRated
                                          ? 'Thank you for rating ${ride.driverName.isNotEmpty ? ride.driverName : "your driver"}!'
                                          : 'How was your ride with ${ride.driverName.isNotEmpty ? ride.driverName : "your driver"}?',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: _hasRated ? const Color(0xFF10B981) : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(5, (starIdx) {
                                        final starNum = starIdx + 1;
                                        final isFilled = starNum <= _riderRating;
                                        return IconButton(
                                          icon: Icon(
                                            Icons.star_rounded,
                                            size: 32,
                                            color: isFilled ? const Color(0xFFF5A623) : const Color(0xFF374151),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _riderRating = starNum;
                                              _hasRated = true;
                                            });
                                          },
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => ReceiptDialogWidget.show(context, ride),
                                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                      label: Text(
                                        'View receipt',
                                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Color(0x33FFFFFF)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => context.go('/rides'),
                                      icon: const Icon(Icons.add_rounded, size: 16),
                                      label: Text(
                                        'Book another',
                                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 2. Cancellation Notice OR 5-Stage Milestone Progression Card
                      if (isCancelled)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0x1AEF4444),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x4DEF4444)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0x33EF4444),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trip Cancelled',
                                      style: GoogleFonts.sora(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'This trip was cancelled. Full fare of $formattedPrice was refunded to your DOGO wallet.',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12.5,
                                        color: const Color(0xFFD1D5DB),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12151E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: Column(
                            children: List.generate(_stages.length, (idx) {
                              final isPassed = idx < validStageIdx;
                              final isCurrent = idx == validStageIdx;

                              return Padding(
                                padding: EdgeInsets.only(bottom: idx < _stages.length - 1 ? 14 : 0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isPassed
                                            ? const Color(0xFF10B981)
                                            : (isCurrent ? const Color(0xFF2563EB) : const Color(0xFF1E2230)),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: isPassed
                                          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                          : Text(
                                              '${idx + 1}',
                                              style: GoogleFonts.sora(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isCurrent ? Colors.white : const Color(0xFF9CA3AF),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        _stageLabels[idx],
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: isCurrent ? FontWeight.w700 : (isPassed ? FontWeight.w600 : FontWeight.w500),
                                          color: isCurrent ? Colors.white : (isPassed ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280)),
                                        ),
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0x332563EB),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Live',
                                          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF60A5FA)),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),

                      const SizedBox(height: 14),

                      // 3. Driver Info Card OR Matching Driver Banner
                      if (ride.status == 'pending')
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12151E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Matching nearby driver...',
                                          style: GoogleFonts.sora(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Dispatched to active drivers on DOGO in real-time.',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Solo test button for instant simulation
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    vm.triggerDemoSimulation();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Simulating driver acceptance and route...'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.play_circle_outline_rounded, size: 15, color: Color(0xFF60A5FA)),
                                  label: Text(
                                    'Solo test: simulate driver acceptance',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF60A5FA),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => CancelRideModal.show(context, ride),
                                  icon: const Icon(Icons.cancel_outlined, size: 15, color: Color(0xFFEF4444)),
                                  label: Text(
                                    'Cancel request',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFEF4444),
                                    side: const BorderSide(color: Color(0x33EF4444)),
                                    backgroundColor: const Color(0x0DEF4444),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12151E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x22FFFFFF)),
                          ),
                          child: Column(
                            children: [
                              // Driver Row
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      ride.driverName.trim().isNotEmpty
                                          ? ride.driverName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
                                          : 'DR',
                                      style: GoogleFonts.sora(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ride.driverName.isNotEmpty ? ride.driverName : 'Abdulmutallib Alasah',
                                          style: GoogleFonts.sora(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${ride.vehicleName} • ${ride.driverPlate.isNotEmpty ? ride.driverPlate : "LAG-605-EK"}',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF5A623)),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${ride.driverRating} • ${ride.driverTrips} trips',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFF5A623),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Call, Chat, & Receipt Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _callDriver(ride.driverPhone),
                                      icon: const Icon(Icons.call_rounded, size: 15),
                                      label: Text('Call', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: StreamBuilder<int>(
                                      stream: TripChatService().streamUnreadCount(ride.code, 'passenger'),
                                      builder: (context, snapshot) {
                                        final unread = snapshot.data ?? 0;
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: () => DriverChatModal.showForRide(context, ride, isDriverMode: false),
                                                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                                                label: Text('Chat', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1E2230),
                                                  foregroundColor: const Color(0xFF60A5FA),
                                                  side: const BorderSide(color: Color(0x3360A5FA)),
                                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                              ),
                                            ),
                                            if (unread > 0)
                                              Positioned(
                                                top: -4,
                                                right: -4,
                                                child: Container(
                                                  padding: const EdgeInsets.all(5),
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFEF4444),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Text(
                                                    '$unread',
                                                    style: GoogleFonts.sora(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => ReceiptDialogWidget.show(context, ride),
                                      icon: const Icon(Icons.receipt_long_rounded, size: 15),
                                      label: Text('Receipt', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Color(0x33FFFFFF)),
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Cancel Ride Action (Only available if not delivered and not cancelled)
                              if (!isCancelled && ride.status != 'delivered' && ride.status != 'completed') ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => CancelRideModal.show(context, ride),
                                    icon: const Icon(Icons.cancel_outlined, size: 15, color: Color(0xFFEF4444)),
                                    label: Text(
                                      'Cancel ride',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFEF4444),
                                      side: const BorderSide(color: Color(0x33EF4444)),
                                      backgroundColor: const Color(0x0DEF4444),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      const SizedBox(height: 14),

                      // 4. Trip PIN Card (Matches Screenshot 2026-10-21 172808.png)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12151E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x4DF5A623)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.security_rounded, size: 16, color: Color(0xFFF5A623)),
                                      const SizedBox(width: 6),
                                      Text(
                                        ride.isCourier ? 'Delivery PIN' : 'Trip PIN',
                                        style: GoogleFonts.sora(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ride.isCourier ? 'Share only when rider delivers.' : 'Share only with your rider.',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 4 PIN Digits with gold circular/pill border
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: ride.pin.split('').map((digit) {
                                  return Container(
                                    width: 38,
                                    height: 44,
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0x24F5A623),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0x66F5A623), width: 1.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      digit,
                                      style: GoogleFonts.sora(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFF5A623),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 5. Payment Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12151E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Paid with ${ride.payment}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedPrice,
                                    style: GoogleFonts.sora(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFF5A623),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => ReceiptDialogWidget.show(context, ride),
                              icon: const Icon(Icons.receipt_rounded, size: 16),
                              label: Text('Receipt', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0x33FFFFFF)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callDriver(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialing $phone...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
