import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/board_view_model.dart';
import '../widgets/new_trip_dialog.dart';

class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final boardVm = context.watch<BoardViewModel>();

    final userFirstName = authVm.displayName.split(' ').first;
    final isDispatcher = authVm.isDispatcher;
    final isDriver = authVm.isDriver;
    final currentUserId = authVm.currentUser?.id;

    return Scaffold(
      floatingActionButton: isDispatcher
          ? FloatingActionButton.extended(
              onPressed: () {
                NewTripDialog.show(
                  context,
                  tripRepo: context.read<TripRepository>(),
                  onTripCreated: () => boardVm.loadTrips(),
                );
              },
              backgroundColor: AppColors.brand,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'New Trip',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => boardVm.loadTrips(),
        color: AppColors.brand,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            // Hero Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF181D2E), AppColors.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi $userFirstName',
                      style: GoogleFonts.sora(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDispatcher
                          ? 'Create trips, assign drivers and keep customers updated.'
                          : 'Pick up a trip and keep your customer in the loop.',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Filter Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem(context, boardVm, BoardTab.open, 'Open', boardVm.openCount),
                          _buildTabItem(context, boardVm, BoardTab.active, 'In progress', boardVm.activeCount),
                          _buildTabItem(context, boardVm, BoardTab.done, 'Finished', boardVm.doneCount),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Trips List
            if (boardVm.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.brand),
                ),
              )
            else if (boardVm.filteredTrips.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route_outlined, size: 48, color: AppColors.textMuted.withAlpha(100)),
                      const SizedBox(height: 12),
                      Text(
                        'No trips here right now.',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final trip = boardVm.filteredTrips[index];
                      final isMine = trip.assignedTo == currentUserId;
                      return _buildTripCard(context, trip, isMine, isDriver, isDispatcher, boardVm);
                    },
                    childCount: boardVm.filteredTrips.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    BoardViewModel vm,
    BoardTab tab,
    String label,
    int count,
  ) {
    final isSelected = vm.currentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setTab(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldBg : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    TripModel trip,
    bool isMine,
    bool isDriver,
    bool isDispatcher,
    BoardViewModel vm,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Service, Code, Status, Payment, Fare
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge.service(trip.service),
                      Text(
                        '#${trip.code}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      StatusBadge.tripStatus(trip.status),
                      StatusBadge.payment(trip.paymentStatus),
                      if (isMine)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.successBorder),
                          ),
                          child: Text(
                            'Yours',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatNaira(trip.fare),
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Pickup & Dropoff
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.radio_button_checked, size: 14, color: AppColors.brandLight),
                    Container(width: 1.5, height: 20, color: AppColors.border),
                    const Icon(Icons.location_on, size: 14, color: AppColors.destructive),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.pickup,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        trip.dropoff,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details Subtext (Customer name, km, notes)
            Text(
              '${trip.distanceKm > 0 ? '${trip.distanceKm} km · ' : ''}${trip.customerName}${trip.notes?.isNotEmpty == true ? ' · ${trip.notes}' : ''}',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isDriver) ...[
              const SizedBox(height: 4),
              Text(
                'You earn ${CurrencyFormatter.formatNaira(trip.driverShare)}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                if (isDriver && trip.status == 'pending' && trip.assignedTo == null && trip.paymentStatus == 'paid')
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final ok = await vm.acceptTrip(trip.id);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trip accepted! Open trip to chat.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Accept Trip',
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                if (isDispatcher && trip.paymentStatus == 'unpaid') ...[
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          final ok = await vm.markPaid(trip.id);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment received — sent to drivers'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Mark Paid',
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isDispatcher || isMine) ...[
                  if (isDriver && trip.status == 'pending' && trip.assignedTo == null && trip.paymentStatus == 'paid')
                    const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: Text(
                          'Open & Chat',
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => context.push('/trips/${trip.id}'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

