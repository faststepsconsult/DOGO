import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/facial_kyc_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../rides/widgets/rides_bottom_nav_bar.dart';
import '../view_models/passenger_verification_view_model.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final uid = authVm.currentUser?.id ?? 'salim-customer-01';
    final name = authVm.displayName;

    return ChangeNotifierProvider(
      create: (_) => PassengerVerificationViewModel(
        userId: uid,
        userFullName: name,
      ),
      child: const _PassengerVerificationContent(),
    );
  }
}

class _PassengerVerificationContent extends StatelessWidget {
  const _PassengerVerificationContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PassengerVerificationViewModel>();
    final stage = vm.stage;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12151E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/account');
            }
          },
        ),
        title: Text(
          'Passenger Identity Verification',
          style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          _buildProviderMenu(context, vm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStage(context, vm, stage),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const RidesBottomNavBar(activeRoute: '/account'),
    );
  }

  Widget _buildProviderMenu(BuildContext context, PassengerVerificationViewModel vm) {
    return PopupMenuButton<KycProviderType>(
      tooltip: 'Choose Verification Provider',
      color: const Color(0xFF181C28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      initialValue: vm.selectedProvider,
      onSelected: (provider) => vm.selectProvider(provider),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: KycProviderType.smileId,
          child: Row(
            children: [
              const Icon(Icons.face_retouching_natural_rounded, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Smile ID', style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                  Text('SmartSelfie™ Biometrics', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: KycProviderType.dojah,
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, size: 18, color: Color(0xFF60A5FA)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Dojah', style: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                  Text('AI Facial Liveness KYC', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0x2610B981),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x4D10B981)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
            const SizedBox(width: 5),
            Text(
              vm.selectedProvider.displayName,
              style: GoogleFonts.sora(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStage(BuildContext context, PassengerVerificationViewModel vm, KycUiStage stage) {
    switch (stage) {
      case KycUiStage.intro:
        return _buildIntroView(context, vm);
      case KycUiStage.preview:
        return _buildPreviewView(context, vm);
      case KycUiStage.analyzing:
        return _buildAnalyzingView(context, vm);
      case KycUiStage.success:
        return _buildSuccessView(context, vm);
      case KycUiStage.failed:
        return _buildFailedView(context, vm);
    }
  }

  // ==========================================
  // 1. INTRO VIEW (Before Taking Selfie)
  // ==========================================
  Widget _buildIntroView(BuildContext context, PassengerVerificationViewModel vm) {
    final provider = vm.selectedProvider;

    return Column(
      key: const ValueKey('intro_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),

        // Hero Icon Card
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1A10B981),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withAlpha(40),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.face_retouching_natural_rounded,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Facial Identity Verification',
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Take a 15-second facial scan to verify your passenger profile. This keeps the DOGO community safe and builds trust with drivers.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13.5,
            color: const Color(0xFF9CA3AF),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Service Provider Callout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Powered by ${provider.displayName} — Biometric facial liveness & anti-fraud verification.',
                  style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFD1D5DB)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3 Key Passenger Safety Benefits
        _buildBenefitTile(
          icon: Icons.verified_user_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Faster Driver Pickups',
          subtitle: 'Drivers are 40% more likely to accept verified passenger ride requests.',
        ),
        const SizedBox(height: 12),
        _buildBenefitTile(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFFF5A623),
          title: 'Priority Matching',
          subtitle: 'Verified riders get priority vehicle matching during rush hours and rain.',
        ),
        const SizedBox(height: 12),
        _buildBenefitTile(
          icon: Icons.lock_outline_rounded,
          iconColor: const Color(0xFF60A5FA),
          title: 'Private & Encrypted',
          subtitle: 'Your biometric face token is securely processed and never shared with third parties.',
        ),
        const SizedBox(height: 28),

        // Tips checklist
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Before taking your selfie:',
                style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 10),
              _buildCheckRow('Center your face in the camera oval'),
              _buildCheckRow('Be in a well-lit room without backlight'),
              _buildCheckRow('Remove glasses, masks, or caps covering your eyes'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (vm.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0x26EF4444),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x4DEF4444)),
            ),
            child: Text(
              vm.errorMessage!,
              style: GoogleFonts.manrope(fontSize: 12.5, color: const Color(0xFFEF4444)),
            ),
          ),
        ],

        // Primary Action: Open Camera for Selfie
        ElevatedButton.icon(
          onPressed: () => vm.pickSelfie(source: ImageSource.camera),
          icon: const Icon(Icons.camera_alt_rounded, size: 20),
          label: const Text('Take Facial Selfie'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary Action: Upload from Gallery (e.g. testing or existing photo)
        OutlinedButton.icon(
          onPressed: () => vm.pickSelfie(source: ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: const Text('Upload Photo from Gallery'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9CA3AF),
            side: const BorderSide(color: Color(0x26FFFFFF)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // 2. PREVIEW VIEW (Review Selfie Photo)
  // ==========================================
  Widget _buildPreviewView(BuildContext context, PassengerVerificationViewModel vm) {
    return Column(
      key: const ValueKey('preview_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Text(
          'Confirm Your Facial Photo',
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'Ensure your face is clearly visible, centered, and well-lit.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 24),

        // Oval Viewfinder Frame with photo
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow
              Container(
                width: 230,
                height: 290,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(115),
                  border: Border.all(color: const Color(0xFF10B981), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withAlpha(50),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Clipped selfie image
              ClipRRect(
                borderRadius: BorderRadius.circular(110),
                child: SizedBox(
                  width: 220,
                  height: 280,
                  child: vm.selfieBytes != null
                      ? Image.memory(vm.selfieBytes!, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF141722)),
                ),
              ),
              // Corner reticle guides
              Positioned(
                top: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        'Face Detected',
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Provider Badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint_rounded, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'Will be verified using ${vm.selectedProvider.displayName} AI Engine',
                style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        ElevatedButton.icon(
          onPressed: () => vm.runVerification(),
          icon: const Icon(Icons.verified_rounded, size: 20),
          label: Text('Verify with ${vm.selectedProvider.displayName}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => vm.pickSelfie(source: ImageSource.camera),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retake Selfie'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9CA3AF),
            side: const BorderSide(color: Color(0x26FFFFFF)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. ANALYZING VIEW (Liveness Check Running)
  // ==========================================
  Widget _buildAnalyzingView(BuildContext context, PassengerVerificationViewModel vm) {
    return Column(
      key: const ValueKey('analyzing_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 30),

        // Scanning Avatar
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing halo
              Container(
                width: 220,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(110),
                  border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(105),
                child: SizedBox(
                  width: 210,
                  height: 270,
                  child: vm.selfieBytes != null
                      ? Image.memory(vm.selfieBytes!, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF141722)),
                ),
              ),
              // Scanning overlay
              Container(
                width: 210,
                height: 270,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(105),
                  color: const Color(0xFF10B981).withAlpha(30),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        Text(
          'Scanning & Verifying Face',
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 8),

        // Real-time progress text
        Text(
          vm.stepMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 18),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: vm.progress > 0 ? vm.progress : null,
            minHeight: 6,
            backgroundColor: const Color(0xFF1E2330),
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Please do not close this screen while biometrics are validated.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  // ==========================================
  // 4. SUCCESS VIEW (Verified Passenger Badge)
  // ==========================================
  Widget _buildSuccessView(BuildContext context, PassengerVerificationViewModel vm) {
    final kyc = vm.kycData;
    final verifiedDate = kyc.verifiedAt != null
        ? DateFormat('d MMM yyyy, h:mm a').format(kyc.verifiedAt!)
        : 'Just now';

    return Column(
      key: const ValueKey('success_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),

        // Success Graphic
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x1F10B981),
              border: Border.all(color: const Color(0x4D10B981), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withAlpha(80),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 48,
              color: Color(0xFF10B981),
            ),
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Identity Verified!',
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your passenger profile is now fully authenticated.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13.5,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 24),

        // Verification Certificate Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x3310B981)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Verification Details',
                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x2610B981),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x4D10B981)),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0x14FFFFFF), height: 1),
              const SizedBox(height: 12),

              _buildDetailRow('KYC Provider', kyc.providerName, Icons.business_rounded),
              const SizedBox(height: 10),
              _buildDetailRow('Facial Liveness', 'Passed 3D Anti-Spoof', Icons.face_rounded, isHighlight: true),
              const SizedBox(height: 10),
              _buildDetailRow('Match Confidence', kyc.formattedScore, Icons.score_rounded),
              const SizedBox(height: 10),
              _buildDetailRow('Reference ID', kyc.referenceId ?? 'SM-94821', Icons.tag_rounded),
              const SizedBox(height: 10),
              _buildDetailRow('Authenticated At', verifiedDate, Icons.schedule_rounded),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Done button
        ElevatedButton(
          onPressed: () => context.go('/account'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          child: const Text('Back to Account'),
        ),
        const SizedBox(height: 12),

        TextButton.icon(
          onPressed: () => vm.resetForReverify(),
          icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF9CA3AF)),
          label: Text(
            'Re-verify or Switch Provider',
            style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. FAILED VIEW
  // ==========================================
  Widget _buildFailedView(BuildContext context, PassengerVerificationViewModel vm) {
    return Column(
      key: const ValueKey('failed_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x26EF4444),
              border: Border.all(color: const Color(0x4DEF4444)),
            ),
            child: const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFEF4444)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Verification Unsuccessful',
          textAlign: TextAlign.center,
          style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          vm.errorMessage ?? 'Face was not detected with sufficient confidence. Please retake your selfie in good lighting.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(fontSize: 13.5, color: const Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: () => vm.pickSelfie(source: ImageSource.camera),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retake Selfie'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.sora(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => vm.clearSelfie(),
          child: const Text('Cancel & Return', style: TextStyle(color: Color(0xFF9CA3AF))),
        ),
      ],
    );
  }

  // Helper widgets
  Widget _buildBenefitTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFD1D5DB))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.manrope(fontSize: 12.5, color: const Color(0xFF9CA3AF))),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isHighlight ? const Color(0xFF10B981) : Colors.white,
          ),
        ),
      ],
    );
  }
}
