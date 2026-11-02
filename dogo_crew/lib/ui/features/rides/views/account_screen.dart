import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/audio_cues_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../widgets/rides_bottom_nav_bar.dart';
import '../widgets/rides_header_widget.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final isAuthenticated = authVm.isAuthenticated;
    final name = authVm.displayName.isNotEmpty ? authVm.displayName : 'Salim Abdulaziz';
    final isWide = MediaQuery.of(context).size.width >= 768;

    final initials = name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      bottomNavigationBar: const RidesBottomNavBar(activeRoute: '/account'),
      body: SafeArea(
        child: Column(
          children: [
            if (isWide) const RidesHeaderWidget(activeRoute: '/account'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Header Title
                        Text(
                          'Account',
                          style: GoogleFonts.sora(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // User Profile Row (Name, Phone, Rating, Avatar)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.sora(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    authVm.phone ?? '+234 803 123 4567',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: const Color(0xFF9CA3AF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '5.00',
                                        style: GoogleFonts.manrope(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: authVm.isClearedDriver
                                              ? const Color(0x1F10B981)
                                              : const Color(0x1F2563EB),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          authVm.isClearedDriver ? 'Cleared Captain' : 'Passenger',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: authVm.isClearedDriver
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF60A5FA),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Profile Avatar
                            GestureDetector(
                              onTap: () => _showEditProfileDialog(context, authVm),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2330),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0x33FFFFFF)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials.isNotEmpty ? initials : 'DG',
                                  style: GoogleFonts.sora(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF60A5FA),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Verification Green Banner Card
                        InkWell(
                          onTap: () => context.go('/verify'),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0x1F10B981),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x3310B981)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0x3310B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFF10B981),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Verified Passenger',
                                        style: GoogleFonts.manrope(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Level 1 KYC Complete • SmileID verified',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: const Color(0xFF10B981),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 3 Quick Action Shortcuts (Trips, Wallet, Safety)
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionShortcut(
                                icon: Icons.history_rounded,
                                label: 'Activity',
                                onTap: () => context.go('/rides/my-trips'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionShortcut(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Wallet',
                                onTap: () => context.go('/rides'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionShortcut(
                                icon: Icons.security_rounded,
                                label: 'Safety',
                                onTap: () => context.go('/rides/help'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Section Title: Preferences & Settings
                        Text(
                          'Preferences & Console',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF9CA3AF),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Menu Tiles List
                        // 1. Captain Console (Driver view)
                        _buildMenuTile(
                          icon: Icons.local_taxi_rounded,
                          title: 'Captain Console',
                          trailing: authVm.isClearedDriver
                              ? _buildStatusPill('Cleared', const Color(0xFF10B981))
                              : _buildStatusPill('Needs Clearance', const Color(0xFFF59E0B)),
                          onTap: () {
                            if (authVm.isClearedDriver) {
                              context.go('/board');
                            } else {
                              context.push('/driver-clearance');
                            }
                          },
                        ),
                        const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),

                        // 2. Driver Clearance (Earn with DOGO)
                        _buildMenuTile(
                          icon: Icons.badge_outlined,
                          title: 'Earn with DOGO (Driver Clearance)',
                          trailing: _buildClearancePill(authVm.driverClearanceStatus),
                          onTap: () => context.push('/driver-clearance'),
                        ),
                        const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),

                        // 4. Switch Testing Persona (Instant Multi-Device Persona Switcher)
                        _buildMenuTile(
                          icon: Icons.people_alt_outlined,
                          title: 'Switch Profile (Multi-Device Testing)',
                          trailing: _buildStatusPill(
                            name.split(' ').first,
                            const Color(0xFF60A5FA),
                          ),
                          onTap: () => _showTestingPersonaPicker(context, authVm),
                        ),
                        const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),

                        // Ride Audio Cues & Sound Alerts
                        _buildMenuTile(
                          icon: AudioCuesService.instance.soundEnabled
                              ? Icons.volume_up_outlined
                              : Icons.volume_off_outlined,
                          title: 'Audio Alerts & Sound Cues',
                          trailing: _buildStatusPill(
                            AudioCuesService.instance.soundEnabled ? 'Enabled' : 'Muted',
                            AudioCuesService.instance.soundEnabled
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          onTap: () async {
                            await AudioCuesService.instance.toggleSound();
                            setState(() {});
                          },
                        ),
                        const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),

                        // 5. Help & Support
                        _buildMenuTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          onTap: () => context.go('/rides/help'),
                        ),
                        const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),

                        // 6. Settings & Profile Edit
                        _buildMenuTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings & Edit Profile',
                          onTap: () => _showEditProfileDialog(context, authVm),
                        ),

                        // Sign out option
                        if (isAuthenticated) ...[
                          const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),
                          _buildMenuTile(
                            icon: Icons.logout_rounded,
                            title: 'Sign out',
                            iconColor: const Color(0xFFEF4444),
                            titleColor: const Color(0xFFEF4444),
                            onTap: () => _confirmSignOut(context, authVm),
                          ),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildClearancePill(String status) {
    if (status == 'active') {
      return _buildStatusPill('Active Captain', const Color(0xFF10B981));
    } else if (status == 'pending') {
      return _buildStatusPill('Under Review', const Color(0xFFF59E0B));
    } else {
      return _buildStatusPill('Apply to Earn', const Color(0xFF60A5FA));
    }
  }

  Widget _buildActionShortcut({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141722),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? const Color(0xFFD1D5DB)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? Colors.white,
                ),
              ),
            ),
            if (trailing != null) ...[
              trailing,
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  /// Multi-device Persona Switcher Modal
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
                'Assign this physical phone a unique identity so multiple test devices operate independently without collision.',
                style: GoogleFonts.manrope(fontSize: 12.5, color: const Color(0xFF9CA3AF), height: 1.4),
              ),
              const SizedBox(height: 18),

              ...AuthRepository.testingPresets.map((preset) {
                final isSelected = authVm.displayName == preset.fullName;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x1F2563EB) : const Color(0xFF0F121B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: preset.isDriver ? const Color(0x1F10B981) : const Color(0x1F2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        preset.isDriver ? Icons.local_taxi_rounded : Icons.person_rounded,
                        color: preset.isDriver ? const Color(0xFF10B981) : const Color(0xFF60A5FA),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      preset.fullName,
                      style: GoogleFonts.sora(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    subtitle: Text(
                      preset.isDriver
                          ? 'Driver • ${preset.vehicle ?? "Car"} • ${preset.phone}'
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

  void _showEditProfileDialog(BuildContext context, AuthViewModel authVm) {
    final nameCtrl = TextEditingController(text: authVm.displayName.isNotEmpty ? authVm.displayName : 'Salim Abdulaziz');
    final phoneCtrl = TextEditingController(text: authVm.phone ?? '+234 803 123 4567');
    final emailCtrl = TextEditingController(text: authVm.email ?? 'salim@dogo.app');
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
            border: Border(
              top: BorderSide(color: Color(0x33FFFFFF)),
            ),
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
                      'Settings & Profile',
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormField('Full Name', nameCtrl, Icons.person_outline_rounded),
                const SizedBox(height: 14),
                _buildFormField('Email Address', emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildFormField('Phone Number', phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildFormField('Vehicle Model (Captains)', vehicleCtrl, Icons.directions_car_outlined),
                const SizedBox(height: 14),
                _buildFormField('License Plate (Captains)', plateCtrl, Icons.pin_outlined),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await authVm.updateProfile(
                        fullName: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        vehicle: vehicleCtrl.text.trim(),
                        plate: plateCtrl.text.trim(),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
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
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, AuthViewModel authVm) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141722),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Sign out?',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to log out of your session?',
            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                authVm.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }
}
