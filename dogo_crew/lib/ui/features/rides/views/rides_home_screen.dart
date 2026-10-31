import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/ride_model.dart';
import '../view_models/rides_view_model.dart';
import '../widgets/booking_sheet_dialog.dart';
import '../widgets/dogo_map_widget.dart';
import '../widgets/rides_bottom_nav_bar.dart';
import '../widgets/rides_header_widget.dart';

class RidesHomeScreen extends StatelessWidget {
  const RidesHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RidesViewModel>();
    final recentRides = vm.recentRides;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      bottomNavigationBar: const RidesBottomNavBar(activeRoute: '/rides'),
      body: Column(
        children: [
          // Top Header Bar
          const RidesHeaderWidget(activeRoute: '/rides'),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Map Banner Section
                      Stack(
                        children: [
                          const DogoMapWidget(height: 280),
                          Positioned(
                            top: 18,
                            left: 18,
                            right: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DOGO Rides',
                                  style: GoogleFonts.sora(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Take a ride or send a package by bike or keke.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // "Where are you going?" Main Action Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12151E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x22FFFFFF), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Where are you going?',
                              style: GoogleFonts.sora(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ride in a Taxi or Keke, or send a package by bike. See your price first.',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // 1. "Book a ride" Button (Blue Brand Button)
                            GestureDetector(
                              onTap: () => BookingSheetDialog.show(context, isDispatch: false),
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withAlpha(80),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
                                    const SizedBox(width: 14),
                                    Text(
                                      'Book a ride',
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(40),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 2. "Send a package" Button (Gold Border Accent Button)
                            GestureDetector(
                              onTap: () => BookingSheetDialog.show(context, isDispatch: true),
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                decoration: BoxDecoration(
                                  color: const Color(0x1AF5A623),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0x66F5A623), width: 1.2),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.inventory_2_outlined, color: Color(0xFFF5A623), size: 20),
                                    const SizedBox(width: 14),
                                    Text(
                                      'Send a package',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5A623).withAlpha(40),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFF5A623)),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 3. Row of 2 Secondary Cards: "Help & support" and "My rides"
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.go('/rides/help'),
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF161922),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0x22FFFFFF)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF60A5FA)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Help & support',
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.manrope(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF9CA3AF)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => context.go('/rides/my-trips'),
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF161922),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0x22FFFFFF)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.route_rounded, size: 18, color: Color(0xFFF5A623)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'My rides',
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.manrope(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF9CA3AF)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 4. "Switch to Driver Console" Card
                            GestureDetector(
                              onTap: () => context.go('/board'),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F261E), Color(0xFF131F2A)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0x4D10B981)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.drive_eta_rounded, color: Color(0xFF10B981), size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Driver Console • Go online',
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'SWITCH',
                                        style: GoogleFonts.manrope(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF10B981)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // "Recent rides" Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent rides',
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/rides/my-trips'),
                            child: Text(
                              'View all',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF60A5FA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (recentRides.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF12141B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x1AFFFFFF)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Your rides will appear here after you book.',
                            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
                          ),
                        )
                      else
                        ...recentRides.map((ride) => _buildRecentRideCard(context, ride)),
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

  Widget _buildRecentRideCard(BuildContext context, RideModel ride) {
    final formattedPrice = '₦${NumberFormat('#,###').format(ride.price)}';

    return GestureDetector(
      onTap: () => context.push('/rides/track/${ride.code}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Row(
          children: [
            // Vehicle Icon with Pulsing Dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0x2E2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    ride.isCourier ? Icons.inventory_2_outlined : Icons.directions_car_rounded,
                    size: 20,
                    color: const Color(0xFF60A5FA),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Code & Route
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.code,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ride.pickup} → ${ride.dropoff}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            // Price in Naira
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formattedPrice,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF5A623),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
