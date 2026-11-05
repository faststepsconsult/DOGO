import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/in_app_call_service.dart';

class InAppCallModal extends StatefulWidget {
  final InAppCallService callService;

  const InAppCallModal({
    super.key,
    required this.callService,
  });

  static Future<void> show(BuildContext context, InAppCallService service) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => InAppCallModal(callService: service),
    );
  }

  @override
  State<InAppCallModal> createState() => _InAppCallModalState();
}

class _InAppCallModalState extends State<InAppCallModal> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnimCtrl;

  @override
  void initState() {
    super.initState();
    _pulseAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _fallbackToCellular(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    widget.callService.endCall(reason: 'switched_to_cellular');
    if (mounted) Navigator.of(context).pop();
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.callService,
      builder: (context, _) {
        final session = widget.callService.currentSession;
        if (session == null || session.status == CallStatus.idle) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        }

        final isIncoming = session.status == CallStatus.incomingRinging;
        final isConnected = session.status == CallStatus.connected;
        final isEnded = session.status == CallStatus.ended;

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF0F121A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Color(0x33FFFFFF), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black87, blurRadius: 30, spreadRadius: 10),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top security & cost pill
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x1A10B981),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x4D10B981)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_calling_3_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text(
                              'DOGO Internet Call • 0 Airtime Used',
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

                  // Peer avatar with pulsing rings
                  Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimCtrl,
                        builder: (context, child) {
                          final scale = isConnected ? 1.0 : (1.0 + (_pulseAnimCtrl.value * 0.08));
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 110 * scale,
                                height: 110 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF10B981).withAlpha((30 * (1 - _pulseAnimCtrl.value)).toInt()),
                                ),
                              ),
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2230),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isConnected ? const Color(0xFF10B981) : const Color(0xFF60A5FA),
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8)),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  session.peerName.isNotEmpty ? session.peerName[0].toUpperCase() : 'D',
                                  style: GoogleFonts.sora(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        session.peerName,
                        style: GoogleFonts.sora(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.peerRole} • Ride #${session.rideCode}',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status indicator badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isConnected ? const Color(0x2210B981) : const Color(0x222563EB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isConnected
                              ? session.formattedDuration
                              : (isEnded
                                  ? 'Call Ended'
                                  : (isIncoming ? 'Incoming Data Call...' : 'Ringing...')),
                          style: GoogleFonts.sora(
                            fontSize: isConnected ? 18 : 13,
                            fontWeight: FontWeight.w700,
                            color: isConnected ? const Color(0xFF10B981) : const Color(0xFF60A5FA),
                            letterSpacing: isConnected ? 1.5 : 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Call action buttons
                  Column(
                    children: [
                      if (isIncoming) ...[
                        // Incoming call options: Decline vs Answer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Decline Button
                            InkWell(
                              onTap: () => widget.callService.endCall(reason: 'declined'),
                              borderRadius: BorderRadius.circular(36),
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Color(0x66EF4444), blurRadius: 16, offset: Offset(0, 6)),
                                  ],
                                ),
                                child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                              ),
                            ),

                            // Answer Button
                            InkWell(
                              onTap: () => widget.callService.answerCall(),
                              borderRadius: BorderRadius.circular(36),
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Color(0x6610B981), blurRadius: 16, offset: Offset(0, 6)),
                                  ],
                                ),
                                child: const Icon(Icons.call_rounded, color: Colors.white, size: 30),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Connected or Outgoing Call Controls: Mute, End, Speaker
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Mute toggle
                            _buildControlRoundButton(
                              icon: session.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              label: session.isMuted ? 'Unmute' : 'Mute',
                              isActive: session.isMuted,
                              onTap: () => widget.callService.toggleMute(),
                            ),

                            // End Call button
                            InkWell(
                              onTap: () => widget.callService.endCall(reason: 'user_ended'),
                              borderRadius: BorderRadius.circular(36),
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Color(0x66EF4444), blurRadius: 16, offset: Offset(0, 6)),
                                  ],
                                ),
                                child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
                              ),
                            ),

                            // Speaker toggle
                            _buildControlRoundButton(
                              icon: session.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                              label: session.isSpeakerOn ? 'Speaker' : 'Earpiece',
                              isActive: session.isSpeakerOn,
                              onTap: () => widget.callService.toggleSpeaker(),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Fallback: cellular call link if poor internet
                      if (session.peerPhone != null && session.peerPhone!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _fallbackToCellular(session.peerPhone),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF9CA3AF)),
                                const SizedBox(width: 6),
                                Text(
                                  'Poor connection? Switch to cellular call',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF9CA3AF),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlRoundButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF374151) : const Color(0xFF1E2230),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? const Color(0xFF60A5FA) : const Color(0x33FFFFFF),
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF60A5FA) : Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

