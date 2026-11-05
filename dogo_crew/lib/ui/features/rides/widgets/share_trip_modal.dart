import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/models/ride_model.dart';

/// Modal bottom sheet allowing passengers to share their live trip status,
/// captain details (name, phone, vehicle model, plate number), and real-time route
/// with family or friends via WhatsApp, SMS, or direct clipboard copy.
class ShareTripModal extends StatelessWidget {
  final RideModel ride;

  const ShareTripModal({super.key, required this.ride});

  /// Displays the ShareTripModal as an interactive bottom sheet
  static Future<void> show(BuildContext context, RideModel ride) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShareTripModal(ride: ride),
    );
  }

  /// Generates the formatted message text containing real-time captain & trip details
  static String generateShareText(RideModel ride) {
    final statusText = _getStatusLabel(ride.status);
    final vehicleDesc = ride.driverVehicle.isNotEmpty ? ride.driverVehicle : ride.vehicleName;
    final plate = ride.driverPlate.isNotEmpty ? ride.driverPlate : 'LAG-472-XA';
    final phone = ride.driverPhone.isNotEmpty ? ride.driverPhone : '+2348024419922';
    final captain = ride.driverName.isNotEmpty ? ride.driverName : 'DOGO Captain';

    final buffer = StringBuffer();
    buffer.writeln('🛡️ DOGO LIVE TRIP TRACKING');
    buffer.writeln('Follow my trip in real-time for safety and arrival info:');
    buffer.writeln();
    buffer.writeln('📍 Pickup: ${ride.pickup}');
    buffer.writeln('🏁 Destination: ${ride.dropoff}');
    buffer.writeln('🚦 Status: $statusText');
    buffer.writeln();
    buffer.writeln('👤 Captain: $captain');
    buffer.writeln('📞 Contact: $phone');
    buffer.writeln('🚗 Vehicle: $vehicleDesc');
    buffer.writeln('🔢 Plate: $plate');
    buffer.writeln();
    buffer.writeln('🔗 Live Tracking Link:');
    buffer.writeln('https://dogo.ng/track/${ride.code}');
    buffer.writeln('Trip ID: #${ride.code}');
    buffer.writeln();
    buffer.writeln('Shared securely via DOGO Urban Mobility.');
    return buffer.toString();
  }

  /// 1-Tap WhatsApp Share
  static Future<void> shareToWhatsApp(BuildContext context, RideModel ride) async {
    final text = generateShareText(ride);
    final whatsappUrl = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    final fallbackUrl = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          await copyToClipboard(context, ride);
        }
      }
    } catch (_) {
      if (context.mounted) {
        await copyToClipboard(context, ride);
      }
    }
  }

  /// 1-Tap SMS Share
  static Future<void> shareToSms(BuildContext context, RideModel ride) async {
    final text = generateShareText(ride);
    final smsUrl = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
      } else {
        if (context.mounted) {
          await copyToClipboard(context, ride);
        }
      }
    } catch (_) {
      if (context.mounted) {
        await copyToClipboard(context, ride);
      }
    }
  }

  /// Copy formatted trip details & live link to clipboard
  static Future<void> copyToClipboard(BuildContext context, RideModel ride) async {
    final text = generateShareText(ride);
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trip details & tracking link copied to clipboard!',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E2230),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Finding Captain';
      case 'accepted':
      case 'confirmed':
        return 'Captain Confirmed';
      case 'to_pickup':
        return 'Captain En Route to Pickup';
      case 'at_pickup':
        return 'Captain Arrived at Pickup';
      case 'on_trip':
      case 'in_transit':
        return 'Trip in Progress to Destination';
      case 'completed':
      case 'delivered':
        return 'Trip Completed';
      default:
        return 'Active Ride';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = _getStatusLabel(ride.status);
    final captainName = ride.driverName.isNotEmpty ? ride.driverName : 'DOGO Captain';
    final vehicleDesc = ride.driverVehicle.isNotEmpty ? ride.driverVehicle : ride.vehicleName;
    final plate = ride.driverPlate.isNotEmpty ? ride.driverPlate : 'LAG-472-XA';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0x33FFFFFF), width: 1),
          left: BorderSide(color: Color(0x22FFFFFF), width: 1),
          right: BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 30,
            spreadRadius: 10,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x44FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Shield Icon + Title + Close Button
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0x1F10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x4D10B981)),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Live Trip',
                        style: GoogleFonts.sora(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Keep loved ones updated with live route & captain info',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 20),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Live Trip Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141722),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: Column(
                children: [
                  // Captain info row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2230),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0x3360A5FA)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          captainName.isNotEmpty ? captainName[0].toUpperCase() : 'C',
                          style: GoogleFonts.sora(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  captainName,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              vehicleDesc,
                              style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                      // Plate Number Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2230),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x4460A5FA)),
                        ),
                        child: Text(
                          plate,
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF93C5FD),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(color: Color(0x14FFFFFF), height: 1),
                  const SizedBox(height: 12),

                  // Route: Pickup -> Destination
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 1.5,
                            height: 22,
                            color: const Color(0x33FFFFFF),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
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
                              ride.pickup,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ride.dropoff,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Status Pill
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0x1A10B981),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x3310B981)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fiber_manual_record_rounded, size: 9, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons: WhatsApp (1-Tap), SMS (1-Tap), Copy Details
            // 1. WhatsApp Button (Primary Green)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                shareToWhatsApp(context, ride);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // Official WhatsApp Green
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Share via WhatsApp',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. SMS Button (Electric Blue)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                shareToSms(context, ride);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sms_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Share via SMS / Messages',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Copy Live Details & Link
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                copyToClipboard(context, ride);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE5E7EB),
                backgroundColor: const Color(0xFF141722),
                side: const BorderSide(color: Color(0x33FFFFFF)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  Text(
                    'Copy Link & Details',
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
