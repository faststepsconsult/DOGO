import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/ride_model.dart';
import '../view_models/rides_view_model.dart';

class CancelRideModal extends StatefulWidget {
  final RideModel ride;

  const CancelRideModal({super.key, required this.ride});

  static Future<bool?> show(BuildContext context, RideModel ride) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancelRideModal(ride: ride),
    );
  }

  @override
  State<CancelRideModal> createState() => _CancelRideModalState();
}

class _CancelRideModalState extends State<CancelRideModal> {
  String _selectedReason = 'Driver is taking too long to arrive';
  final TextEditingController _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  static const List<String> _reasons = [
    'Driver is taking too long to arrive',
    'Found another ride / Changed my mind',
    'Driver requested cancellation',
    'Wrong pickup or dropoff location entered',
    'Emergency / Other reason',
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmCancel() async {
    setState(() => _isSubmitting = true);
    final vm = context.read<RidesViewModel>();
    final formattedPrice = '₦${NumberFormat('#,###').format(widget.ride.price)}';

    final success = vm.cancelRide(widget.ride.code, reason: _selectedReason);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Row(
            children: [
              const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Trip #${widget.ride.code} cancelled. $formattedPrice refunded to your wallet.',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final formattedPrice = '₦${NumberFormat('#,###').format(ride.price)}';
    final isFullRefund = ride.status == 'confirmed' || ride.status == 'picked_up';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: bottomInset + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF141722),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x33EF4444), width: 1)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0x26EF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Cancel Trip #${ride.code}?',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.sora(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
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
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 20),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Refund Information Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isFullRefund ? const Color(0x1A10B981) : const Color(0x1AF5A623),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isFullRefund ? const Color(0x4D10B981) : const Color(0x4DF5A623),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFullRefund ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                        color: isFullRefund ? const Color(0xFF10B981) : const Color(0xFFF5A623),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFullRefund ? '100% Instant Refund Guaranteed' : 'Cancellation Notice',
                              style: GoogleFonts.sora(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isFullRefund ? const Color(0xFF10B981) : const Color(0xFFF5A623),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFullRefund
                                  ? 'You will receive a full refund of $formattedPrice back to your DOGO wallet balance immediately.'
                                  : 'Trip is currently underway. A cancellation fee may apply depending on route progress.',
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Reason Selection Header
                Text(
                  'Please select a reason for cancelling:',
                  style: GoogleFonts.sora(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Reasons List
                ..._reasons.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return InkWell(
                    onTap: () => setState(() => _selectedReason = reason),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0x1F2563EB) : const Color(0xFF0D0F14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF6B7280),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reason,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 8),

                // Optional Additional Notes
                Text(
                  'Additional notes (optional):',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tell us what happened...',
                    hintStyle: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF6B7280)),
                    filled: true,
                    fillColor: const Color(0xFF0D0F14),
                    contentPadding: const EdgeInsets.all(12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2563EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0x33FFFFFF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: Text(
                          'Keep My Ride',
                          style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleConfirmCancel,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.cancel_rounded, size: 16),
                        label: Text(
                          _isSubmitting ? 'Cancelling...' : 'Confirm Cancel',
                          style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
