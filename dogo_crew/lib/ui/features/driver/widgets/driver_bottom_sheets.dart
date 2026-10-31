import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/driver_view_model.dart';

class DriverBottomSheets extends StatelessWidget {
  final DriverViewModel vm;
  final String driverName;

  const DriverBottomSheets({
    super.key,
    required this.vm,
    required this.driverName,
  });

  static Future<void> _callPassenger(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dialing passenger at $cleanPhone...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (vm.session) {
      case DriverSession.offline:
        return _buildOfflineSheet(context);
      case DriverSession.online:
        return _buildOnlineSheet(context);
      case DriverSession.request:
        return _buildRequestSheet(context);
      case DriverSession.toPickup:
        return _buildToPickupSheet(context);
      case DriverSession.atPickup:
        return _AtPickupSheetWidget(
          vm: vm,
          onCallPassenger: (phone) => _callPassenger(context, phone),
        );
      case DriverSession.onTrip:
        return _buildOnTripSheet(context);
      case DriverSession.complete:
        return _buildCompleteSheet(context);
    }
  }

  // 1. Offline Sheet
  Widget _buildOfflineSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0x1F10B981),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x3310B981)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your driver account is active — welcome aboard, $driverName!',
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're offline",
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Turn on to start receiving ride requests.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              Switch(
                value: false,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: (_) => vm.toggleOnline(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Online Sheet
  Widget _buildOnlineSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You're online",
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Looking for ride requests near you…',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: true,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: (_) => vm.toggleOnline(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F121B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        CurrencyFormatter.formatNaira(vm.todayEarnings),
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Today',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0x1FFFFFFF)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${vm.completedTripsCount}',
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trips',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0x1FFFFFFF)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${vm.driverShare}%',
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your share',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Dispatch Active — Waiting for passenger requests',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: InkWell(
              onTap: () => vm.triggerSimulatedRequest(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1F2563EB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x402563EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_outline_rounded, size: 14, color: Color(0xFF60A5FA)),
                    const SizedBox(width: 6),
                    Text(
                      'Simulate test request (demo)',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF60A5FA),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Request Sheet
  Widget _buildRequestSheet(BuildContext context) {
    final req = vm.currentRequest;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger Row with Countdown Timer
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF22283A),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  req.initials,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.passenger,
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 15, color: Color(0xFF10B981)),
                        const SizedBox(width: 3),
                        Text(
                          '${req.rating} · pays ${req.payment.toLowerCase()}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Circular Countdown Ring
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: vm.secondsLeft / DriverViewModel.requestDurationSeconds,
                      backgroundColor: const Color(0xFF22283A),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      strokeWidth: 4,
                    ),
                    Text(
                      '${vm.secondsLeft}',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Route Addresses
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 1.5, height: 26, color: const Color(0x33FFFFFF)),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.pickupName,
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      req.dropoffName,
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Earnings Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F121B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.formatNaira(req.driverPayout),
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your earnings',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${req.distanceKm} km trip',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '~${req.minutes} min',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Decline & Accept
          Row(
            children: [
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => vm.declineRide(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x33FFFFFF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Decline',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final authVm = context.read<AuthViewModel>();
                      vm.acceptRide(
                        driverId: authVm.currentUser?.id,
                        driverName: driverName,
                        driverPhone: authVm.phone,
                        driverPlate: authVm.plate,
                        driverVehicle: authVm.vehicle,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.navigation_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Accept ride',
                          style: GoogleFonts.sora(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. To Pickup Sheet
  Widget _buildToPickupSheet(BuildContext context) {
    final req = vm.currentRequest;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ON THE WAY TO PICKUP',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  req.pickupName,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '4 min',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    '1.2 km',
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
                    children: [
                      const TextSpan(text: 'Passenger: '),
                      TextSpan(
                        text: req.passenger,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _callPassenger(context, req.passengerPhone),
                icon: const Icon(Icons.call_rounded, size: 14),
                label: Text('Call', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0x3310B981)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => vm.arrivedAtPickup(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                "I've arrived",
                style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => vm.cancelRide(),
              child: Text(
                'Cancel ride',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. At Pickup Sheet Widget is defined below as _AtPickupSheetWidget

  // 6. On Trip Sheet
  Widget _buildOnTripSheet(BuildContext context) {
    final req = vm.currentRequest;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IN TRIP',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.navigation_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  req.dropoffName,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '~${req.minutes} min',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    '${req.distanceKm} km left',
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Animated transit bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.72,
              minHeight: 6,
              backgroundColor: Color(0xFF22283A),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => vm.completeTrip(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Complete trip',
                style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Complete Sheet / Dialog
  Widget _buildCompleteSheet(BuildContext context) {
    final req = vm.currentRequest;
    final payout = req.driverPayout;
    final gross = req.fare;
    final commission = req.commission;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F121B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            'Trip complete!',
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${req.passenger} was dropped off at the destination.',
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Text(
            CurrencyFormatter.formatNaira(payout),
            style: GoogleFonts.sora(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF10B981),
            ),
          ),
          Text(
            "Added to today's earnings",
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 18),

          // Breakdown Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF141722),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fare collected', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF))),
                    Text(CurrencyFormatter.formatNaira(gross), style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DOGO commission (15%)', style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF))),
                    Text('-${CurrencyFormatter.formatNaira(commission)}', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const Divider(color: Color(0x1FFFFFFF), height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your payout', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text(CurrencyFormatter.formatNaira(payout), style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Rate your passenger',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNum = index + 1;
              final filled = starNum <= vm.ratingStars;
              return IconButton(
                icon: Icon(
                  Icons.star_rounded,
                  size: 30,
                  color: filled ? const Color(0xFF10B981) : const Color(0xFF374151),
                ),
                onPressed: () => vm.setRating(starNum),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => vm.continueAfterComplete(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AtPickupSheetWidget extends StatefulWidget {
  final DriverViewModel vm;
  final Function(String phone) onCallPassenger;

  const _AtPickupSheetWidget({
    required this.vm,
    required this.onCallPassenger,
  });

  @override
  State<_AtPickupSheetWidget> createState() => _AtPickupSheetWidgetState();
}

class _AtPickupSheetWidgetState extends State<_AtPickupSheetWidget> {
  final TextEditingController _pinController = TextEditingController();
  String? _pinError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyAndStart() {
    final entered = _pinController.text.trim();
    if (widget.vm.pinVerified || widget.vm.verifyPin(entered)) {
      widget.vm.startTrip();
    } else {
      setState(() {
        _pinError = 'Incorrect PIN. Please ask the passenger for their 4-digit code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.vm.currentRequest;
    final minutes = widget.vm.waitSeconds ~/ 60;
    final seconds = widget.vm.waitSeconds % 60;
    final waitString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isVerified = widget.vm.pinVerified;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Wait Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "YOU'VE ARRIVED AT PICKUP",
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10B981),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Waiting for ${req.passenger}',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F121B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  children: [
                    Text(
                      waitString,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'wait time',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Passenger info & Call
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F121B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22283A),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    req.initials,
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.pickupName,
                        style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        req.passengerPhone.isNotEmpty ? req.passengerPhone : '+2348031234567',
                        style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onCallPassenger(req.passengerPhone),
                  icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 20),
                  tooltip: 'Call passenger',
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // PIN Verification Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isVerified ? const Color(0x1F10B981) : const Color(0xFF0F121B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isVerified ? const Color(0x6610B981) : const Color(0x33F5A623)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isVerified ? Icons.check_circle_rounded : Icons.pin_rounded,
                          size: 16,
                          color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF5A623),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isVerified ? 'PIN Verified' : 'Verify Trip PIN',
                          style: GoogleFonts.sora(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isVerified ? const Color(0xFF10B981) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (!isVerified)
                      Text(
                        'Ask passenger for code',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isVerified)
                  Text(
                    'Passenger identity confirmed. You may now start the trip.',
                    style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFD1D5DB)),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 4),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '4-digit PIN',
                              hintStyle: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF6B7280), letterSpacing: 0),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              filled: true,
                              fillColor: const Color(0xFF141722),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0x33FFFFFF))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
                            ),
                            onChanged: (val) {
                              if (val.length == 4) {
                                if (widget.vm.verifyPin(val)) {
                                  setState(() => _pinError = null);
                                } else {
                                  setState(() => _pinError = 'Incorrect PIN. Ask passenger for their code.');
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.vm.verifyPin(_pinController.text)) {
                            setState(() => _pinError = null);
                          } else {
                            setState(() => _pinError = 'Incorrect PIN. Ask passenger for their code.');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2230),
                          foregroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Verify', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                if (_pinError != null) ...[
                  const SizedBox(height: 4),
                  Text(_pinError!, style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFFEF4444))),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Start trip button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _verifyAndStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Start trip',
                style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => widget.vm.cancelRide(),
              child: Text(
                'Cancel ride',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
