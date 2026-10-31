import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/ride_model.dart';
import '../view_models/rides_view_model.dart';
import '../widgets/rides_bottom_nav_bar.dart';
import '../widgets/rides_header_widget.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  String _selectedFilter = 'all'; // 'all', 'rides', 'courier'

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RidesViewModel>();
    final allRides = vm.allRides;

    final filteredRides = allRides.where((r) {
      if (_selectedFilter == 'rides') return !r.isCourier;
      if (_selectedFilter == 'courier') return r.isCourier;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      bottomNavigationBar: const RidesBottomNavBar(activeRoute: '/rides/my-trips'),
      body: Column(
        children: [
          const RidesHeaderWidget(activeRoute: '/rides/my-trips'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your trips',
                        style: GoogleFonts.sora(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose a trip to see where it is.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All trips', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Rides', 'rides'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Packages', 'courier'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (filteredRides.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141722),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x1FFFFFFF)),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_car_outlined, size: 40, color: Color(0xFF6B7280)),
                              const SizedBox(height: 12),
                              Text(
                                'No rides found',
                                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Book your first ride from the Home screen.',
                                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredRides.map((ride) => _buildTripCard(context, ride)),
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

  Widget _buildFilterChip(String label, String filterKey) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filterKey),
      backgroundColor: const Color(0xFF161922),
      selectedColor: const Color(0xFF2563EB).withAlpha(40),
      labelStyle: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFF9CA3AF),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, RideModel ride) {
    final formattedPrice = '₦${NumberFormat('#,###').format(ride.price)}';

    return GestureDetector(
      onTap: () => context.push('/rides/track/${ride.code}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          children: [
            // Vehicle Icon with Live Dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0x2E2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    ride.isCourier ? Icons.inventory_2_outlined : Icons.directions_car_rounded,
                    size: 22,
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

            // Code & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.code,
                    style: GoogleFonts.sora(
                      fontSize: 15,
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x2E10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ride.status.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ride.vehicleName,
                        style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price in Gold
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formattedPrice,
                style: GoogleFonts.sora(
                  fontSize: 15,
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
