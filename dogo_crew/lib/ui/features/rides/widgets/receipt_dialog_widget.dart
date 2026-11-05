import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../data/models/ride_model.dart';
import 'share_trip_modal.dart';

class ReceiptDialogWidget extends StatelessWidget {
  final RideModel ride;

  const ReceiptDialogWidget({super.key, required this.ride});

  static void show(BuildContext context, RideModel ride) {
    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialogWidget(ride: ride),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedPrice = '₦${NumberFormat('#,###').format(ride.price)}';
    final formattedDate = DateFormat('MMM d, y • h:mm a').format(ride.createdAt);

    return Dialog(
      backgroundColor: const Color(0xFF10131B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x33FFFFFF), width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Digital receipt',
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Code & QR Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x24FFFFFF)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOGO RIDES',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF5A623),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ride.code,
                            style: GoogleFonts.sora(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(
                        data: 'DOGO|${ride.code}|${ride.pin}',
                        version: QrVersions.auto,
                        size: 72.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Breakdown rows
              _buildRow('Trip code', ride.code),
              _buildRow('Pickup', ride.pickup),
              _buildRow('Destination', ride.dropoff),
              _buildRow('Vehicle', ride.vehicleName),
              if (ride.isCourier) ...[
                _buildRow('Package', '${ride.packageType} • ${ride.weight > 0 ? "${ride.weight} kg" : "Parcel"}'),
                if (ride.recipientName.isNotEmpty)
                  _buildRow('Recipient', '${ride.recipientName} (${ride.recipientPhone})'),
              ],
              _buildRow('Payment method', ride.payment),
              _buildRow('Distance', '${ride.distanceKm} km'),

              const SizedBox(height: 16),

              // Total Paid Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0x1AF5A623),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x4DF5A623)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total paid',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      formattedPrice,
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF5A623),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Print / Done Button
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receipt downloaded to device storage.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF2563EB),
                    ),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.print_outlined, size: 16),
                label: Text(
                  'Print / Save receipt',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ShareTripModal.show(context, ride);
                },
                icon: const Icon(Icons.share_location_rounded, size: 16, color: Color(0xFF10B981)),
                label: Text(
                  'Share trip details (WhatsApp / SMS)',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x3310B981)),
                  backgroundColor: const Color(0x1A10B981),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
