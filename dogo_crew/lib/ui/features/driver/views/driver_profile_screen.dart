import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/driver_view_model.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final driverVm = context.watch<DriverViewModel>();
    final driverName = authVm.displayName.isNotEmpty ? authVm.displayName : 'Abdulmutallib Alasah';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F14),
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Avatar & Name Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141722),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/images/driver-avatar.png',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1F2433),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, size: 36, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: GoogleFonts.sora(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'New driver · Joined Oct 2026',
                                style: GoogleFonts.manrope(
                                  fontSize: 12.5,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFF10B981)),
                                    const SizedBox(width: 3),
                                    Text(
                                      '5.0',
                                      style: GoogleFonts.sora(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rating',
                                  style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 26, color: const Color(0x1FFFFFFF)),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${driverVm.completedTripsCount}',
                                  style: GoogleFonts.sora(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Trips',
                                  style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 26, color: const Color(0x1FFFFFFF)),
                          Expanded(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.sora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Account',
                                  style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Vehicle Card
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF141722),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/vehicle-corolla.png',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 120,
                        color: const Color(0xFF1F2433),
                        child: const Center(
                          child: Icon(Icons.directions_car_rounded, size: 50, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1F2433),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_car_rounded, size: 20, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toyota Corolla 2018',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'White · Sedan · 4 seats',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Menu Rows
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141722),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      icon: Icons.assignment_outlined,
                      label: 'Documents',
                      value: 'Approved',
                      onTap: () => context.go('/crew-verify'),
                    ),
                    const Divider(color: Color(0x14FFFFFF), height: 1, indent: 52),
                    _buildRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Payment method',
                      value: 'Cash & Card',
                      onTap: () {},
                    ),
                    const Divider(color: Color(0x14FFFFFF), height: 1, indent: 52),
                    _buildRow(
                      icon: Icons.shield_outlined,
                      label: 'Safety centre',
                      onTap: () {},
                    ),
                    const Divider(color: Color(0x14FFFFFF), height: 1, indent: 52),
                    _buildRow(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {},
                    ),
                    const Divider(color: Color(0x14FFFFFF), height: 1, indent: 52),
                    _buildRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Support',
                      onTap: () => context.go('/rides/help'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Switch to Rider App Button
              InkWell(
                onTap: () => context.go('/rides'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141722),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, color: Color(0xFF10B981), size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Switch to Rider app',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Reset Demo Data
              InkWell(
                onTap: () {
                  driverVm.resetDemoData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Driver demo state reset.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141722),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded, color: Color(0xFFEF4444), size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Reset demo data',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}
