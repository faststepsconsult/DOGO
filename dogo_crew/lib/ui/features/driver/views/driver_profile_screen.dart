import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/driver_view_model.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final driverVm = context.watch<DriverViewModel>();
    final driverName = authVm.displayName.isNotEmpty ? authVm.displayName : 'Ibrahim Musa';
    final vehicle = authVm.vehicle ?? 'Toyota Corolla 2018 (Silver)';
    final plate = authVm.plate ?? 'LAG-605-EK';
    final phone = authVm.phone ?? '+234 802 441 9922';

    final initials = driverName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F14),
        elevation: 0,
        title: Text(
          'Captain Profile',
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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1F2433),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials.isNotEmpty ? initials : 'CP',
                            style: GoogleFonts.sora(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
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
                                phone,
                                style: GoogleFonts.manrope(
                                  fontSize: 12.5,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF60A5FA), size: 20),
                          tooltip: 'Edit Profile',
                          onPressed: () => _showEditDriverProfileModal(context, authVm),
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
                                      '${driverVm.driverRating}',
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
                                      authVm.isClearedDriver ? 'Cleared' : 'Pending',
                                      style: GoogleFonts.sora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: authVm.isClearedDriver
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Clearance',
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
                                  vehicle,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Plate: $plate',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w600,
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
                      icon: Icons.badge_outlined,
                      label: 'Driver Clearance',
                      value: authVm.isClearedDriver ? 'Approved' : 'Pending',
                      onTap: () => context.push('/driver-clearance'),
                    ),
                    const Divider(color: Color(0x14FFFFFF), height: 1, indent: 52),
                    _buildRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Earnings & Payout',
                      value: '₦${driverVm.todayEarnings}',
                      onTap: () => context.go('/crew-earnings'),
                    ),
                    const Divider(color: Color(0x14FFFFFF), height: 1, indent: 52),
                    _buildRow(
                      icon: Icons.people_alt_outlined,
                      label: 'Switch Persona (Testing)',
                      value: driverName.split(' ').first,
                      onTap: () => _showTestingPersonaPicker(context, authVm),
                    ),
                    const Divider(color: Color(0x14FFFFFF), height: 1, indent: 52),
                    _buildRow(
                      icon: Icons.settings_outlined,
                      label: 'Vehicle & Account Settings',
                      onTap: () => _showEditDriverProfileModal(context, authVm),
                    ),
                    const Divider(color: Color(0x14FFFFFF), height: 1, indent: 52),
                    _buildRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Support & Help',
                      onTap: () => context.go('/rides/help'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Switch to Passenger App Button
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
                          'Switch to Passenger App',
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
                      content: Text('Driver state reset.'),
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
                          'Reset demo trips',
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

  void _showEditDriverProfileModal(BuildContext context, AuthViewModel authVm) {
    final nameCtrl = TextEditingController(text: authVm.displayName);
    final phoneCtrl = TextEditingController(text: authVm.phone ?? '+234 802 441 9922');
    final vehicleCtrl = TextEditingController(text: authVm.vehicle ?? 'Toyota Corolla 2018 (Silver)');
    final plateCtrl = TextEditingController(text: authVm.plate ?? 'LAG-605-EK');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF141722),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Captain & Vehicle Details',
                      style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Full Name', nameCtrl, Icons.person_rounded),
                const SizedBox(height: 14),
                _buildField('Phone Number', phoneCtrl, Icons.phone_rounded, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildField('Vehicle Model & Color', vehicleCtrl, Icons.directions_car_rounded),
                const SizedBox(height: 14),
                _buildField('License Plate', plateCtrl, Icons.pin_rounded),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await authVm.updateProfile(
                        fullName: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        vehicle: vehicleCtrl.text.trim(),
                        plate: plateCtrl.text.trim().toUpperCase(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Driver details updated!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTestingPersonaPicker(BuildContext context, AuthViewModel authVm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF141722),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Multi-Device Persona',
                    style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Assign this physical phone a driver persona to test multiplayer dispatches.',
                style: GoogleFonts.manrope(fontSize: 12.5, color: const Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 18),
              ...AuthRepository.testingPresets.map((preset) {
                final isSelected = authVm.displayName == preset.fullName;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x1F10B981) : const Color(0xFF0F121B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF10B981) : const Color(0x1FFFFFFF),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Icon(
                      preset.isDriver ? Icons.local_taxi_rounded : Icons.person_rounded,
                      color: preset.isDriver ? const Color(0xFF10B981) : const Color(0xFF60A5FA),
                    ),
                    title: Text(
                      preset.fullName,
                      style: GoogleFonts.sora(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    subtitle: Text(
                      preset.isDriver
                          ? 'Driver • ${preset.vehicle} • ${preset.plate}'
                          : 'Passenger • ${preset.phone}',
                      style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await authVm.switchProfilePreset(preset);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched to ${preset.fullName}!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFF0D0F14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981)),
            ),
          ),
        ),
      ],
    );
  }
}
