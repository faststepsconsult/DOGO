import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';

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

                        // User Profile Row (Name, Rating, Camera Avatar)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.sora(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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
                                    const SizedBox(width: 4),
                                    const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                                  ],
                                ),
                              ],
                            ),
                            // Camera / Profile Button
                            GestureDetector(
                              onTap: () => _showEditProfileDialog(context, authVm),
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2330),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0x33FFFFFF)),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 22,
                                  color: Colors.white,
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
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Enjoy smoother and safer rides',
                                        style: GoogleFonts.sora(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Verify identity',
                                        style: GoogleFonts.sora(
                                          fontSize: 14,
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
                        ),
                        const SizedBox(height: 24),

                        // Signed-out banner prompt if not signed in
                        if (!isAuthenticated) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141722),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x1FFFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Sign in to access your saved trips and driver tools',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => context.go('/auth'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Sign In or Register'),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Driver Mode Switcher Banner (Instant Role Flip)
                        InkWell(
                          onTap: () => context.go('/board'),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D251C), Color(0xFF141926)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0x4D10B981), width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2610B981),
                                  blurRadius: 14,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0x2E10B981),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0x6610B981)),
                                  ),
                                  child: const Icon(Icons.drive_eta_rounded, color: Color(0xFF10B981), size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Driver Mode',
                                            style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'ONLINE CONSOLE',
                                              style: GoogleFonts.manrope(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.black),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Go online & accept live ride requests',
                                        style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Switch',
                                        style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.black),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.swap_horiz_rounded, size: 15, color: Colors.black),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Menu items:
                        // 1. Driver Console
                        _buildMenuTile(
                          icon: Icons.drive_eta_rounded,
                          title: 'Driver Console',
                          iconColor: const Color(0xFF10B981),
                          onTap: () => context.go('/board'),
                        ),
                        const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),

                        // 2. Verification
                        _buildMenuTile(
                          icon: Icons.verified_user_outlined,
                          title: 'Verification',
                          onTap: () => context.go('/verify'),
                        ),
                        const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),

                        // 3. Driver Clearance
                        _buildMenuTile(
                          icon: Icons.badge_outlined,
                          title: 'Earn with DOGO (Driver Clearance)',
                          onTap: () => _openDriverRegistration(context),
                        ),
                        const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),

                        // 3. Help
                        _buildMenuTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help',
                          onTap: () => context.go('/rides/help'),
                        ),
                        const Divider(color: Color(0x14FFFFFF), height: 1, indent: 42),

                        // 4. Settings
                        _buildMenuTile(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
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
            Icon(icon, size: 24, color: iconColor ?? const Color(0xFFD1D5DB)),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthViewModel authVm) {
    final nameCtrl = TextEditingController(text: authVm.displayName.isNotEmpty ? authVm.displayName : 'Salim Abdulaziz');
    final phoneCtrl = TextEditingController(text: authVm.phone ?? '+234 803 123 4567');
    final vehicleCtrl = TextEditingController(text: authVm.vehicle ?? 'Toyota Corolla (Taxi)');
    final plateCtrl = TextEditingController(text: authVm.plate ?? 'LAG-482-XA');

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
                _buildFormField('Phone Number', phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _buildFormField('Vehicle Model (Drivers)', vehicleCtrl, Icons.directions_car_outlined),
                const SizedBox(height: 14),
                _buildFormField('License Plate (Drivers)', plateCtrl, Icons.pin_outlined),
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

  Future<void> _openDriverRegistration(BuildContext context) async {
    final uri = Uri.parse(AppConstants.driverOnboardingUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening driver clearing website: ${AppConstants.driverOnboardingUrl}'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirecting to driver clearing portal...'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
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
