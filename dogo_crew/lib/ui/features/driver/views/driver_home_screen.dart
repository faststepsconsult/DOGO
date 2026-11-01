import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/driver_view_model.dart';
import '../widgets/driver_bottom_sheets.dart';
import '../widgets/driver_map_widget.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverVm = context.watch<DriverViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final driverName = authVm.displayName.isNotEmpty ? authVm.displayName : 'Abdulmutallib Alasah';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Interactive Offline Map Artwork
            Positioned.fill(
              child: DriverMapWidget(
                session: driverVm.session,
                request: driverVm.currentRequest,
              ),
            ),

            // Floating Top Header
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Rides / Switch Mode Pill
                  InkWell(
                    onTap: () => context.go('/rides'),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141722),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            'Rider Mode',
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Today's Earnings Pill
                  InkWell(
                    onTap: () => context.go('/crew-earnings'),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141722),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0x33FFFFFF)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            CurrencyFormatter.formatNaira(driverVm.todayEarnings),
                            style: GoogleFonts.sora(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'today',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sound / Audio Alerts Toggle
                  InkWell(
                    onTap: () => driverVm.toggleSound(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: driverVm.soundEnabled ? const Color(0xFF141722) : const Color(0x33EF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: driverVm.soundEnabled ? const Color(0x33FFFFFF) : const Color(0x88EF4444),
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Icon(
                        driverVm.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        size: 20,
                        color: driverVm.soundEnabled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),

                  // Profile Icon Shortcut
                  InkWell(
                    onTap: () => context.go('/crew-profile'),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141722),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x33FFFFFF)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.person_outline_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Informational notification banner (e.g. "Another driver accepted first")
            if (driverVm.sessionMessage != null)
              Positioned(
                top: 72,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2230),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF5A623)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFF5A623), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          driverVm.sessionMessage!,
                          style: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => driverVm.clearSessionMessage(),
                        child: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // Dynamic Bottom Sheets
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DriverBottomSheets(
                vm: driverVm,
                driverName: driverName,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
