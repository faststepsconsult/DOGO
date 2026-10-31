import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/rides_view_model.dart';
import 'dogo_wallet_modal.dart';

class RidesHeaderWidget extends StatelessWidget {
  final String activeRoute;

  const RidesHeaderWidget({
    super.key,
    required this.activeRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xE60D0F14),
        border: Border(
          bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Brand Logo & Title (Scale-down safe)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.go('/rides'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withAlpha(80),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'D',
                            style: GoogleFonts.sora(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DOGO',
                              style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'RIDES',
                              style: GoogleFonts.manrope(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFF5A623),
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Right controls cluster (FittedBox inside Expanded - 100% overflow-proof)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Desktop Nav Links
                          if (isWide) ...[
                            _buildNavLink(context, 'Home', '/rides', activeRoute == '/rides'),
                            const SizedBox(width: 8),
                            _buildNavLink(context, 'My trips', '/rides/my-trips', activeRoute == '/rides/my-trips'),
                            const SizedBox(width: 8),
                            _buildNavLink(context, 'Account', '/account', activeRoute == '/account'),
                            const SizedBox(width: 8),
                            _buildNavLink(context, 'Verification', '/verify', activeRoute == '/verify'),
                            const SizedBox(width: 8),
                            _buildNavLink(context, 'Help', '/rides/help', activeRoute == '/rides/help'),
                            const SizedBox(width: 12),
                          ],

                          // Wallet Pill (Tap to open DOGO Wallet Modal)
                          GestureDetector(
                            onTap: () => DogoWalletModal.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0x1AF5A623),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0x4DF5A623)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 13,
                                    color: Color(0xFFF5A623),
                                  ),
                                  const SizedBox(width: 4),
                                  Builder(
                                    builder: (ctx) {
                                      String bal = '₦184,500';
                                      try {
                                        final vm = ctx.watch<RidesViewModel>();
                                        bal = vm.formattedWalletBalance;
                                      } catch (_) {}
                                      return Text(
                                        bal,
                                        style: GoogleFonts.sora(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFF5A623),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Customer Account / Profile Avatar
                          GestureDetector(
                            onTap: () => _showAccountSheet(context),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getInitials(context),
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, String label, String route, bool isActive) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1F2937) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  String _getInitials(BuildContext context) {
    try {
      final authVm = Provider.of<AuthViewModel>(context, listen: false);
      final name = authVm.displayName;
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    } catch (_) {}
    return 'SB';
  }

  void _showAccountSheet(BuildContext context) {
    AuthViewModel? authVm;
    try {
      authVm = Provider.of<AuthViewModel>(context, listen: false);
    } catch (_) {}

    final name = authVm?.displayName ?? 'Salim Bello';
    final email = authVm?.currentUser?.email ?? 'salim@dogo.ng';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10131B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/account');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _getInitials(context),
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
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.sora(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF9CA3AF)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Passenger • $email',
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
                const SizedBox(height: 16),

                // Switch to Driver Mode Action Banner
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/board');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x1F10B981),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x6610B981), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0x2610B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.drive_eta_rounded, size: 20, color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Switch to Driver Console',
                                style: GoogleFonts.manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Go online to accept incoming ride requests',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF10B981)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(color: Color(0x1FFFFFFF), height: 1),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF60A5FA)),
                  title: Text(
                    'Account & profile',
                    style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/account');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFF5A623)),
                  title: Text(
                    'Wallet balance',
                    style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (ctx) {
                          String bal = '₦184,500';
                          try {
                            final vm = ctx.watch<RidesViewModel>();
                            bal = vm.formattedWalletBalance;
                          } catch (_) {}
                          return Text(
                            bal,
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF5A623),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 18),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    DogoWalletModal.show(context);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.route_rounded, color: Color(0xFF60A5FA)),
                  title: Text(
                    'My trips',
                    style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/rides/my-trips');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.support_agent_rounded, color: Color(0xFF10B981)),
                  title: Text(
                    'Help & support',
                    style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/rides/help');
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      authVm?.signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0x33EF4444)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
