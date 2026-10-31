import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/rides_bottom_nav_bar.dart';
import '../widgets/rides_header_widget.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _tripCodeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  static const List<String> _topics = [
    'Ride problem',
    'Package problem',
    'Payment or refund',
    'Vehicle verification',
    'Safety concern',
    'Something else',
  ];

  String _selectedTopic = _topics.first;
  String? _caseId;

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How do I cancel a ride?',
      'a': 'Open My trips, choose the trip and contact your driver or submit a ticket here with your trip code.'
    },
    {
      'q': 'My package hasn\'t arrived',
      'a': 'Check the live tracking page for real-time driver progress. If it is delayed, report it below.'
    },
    {
      'q': 'How do drivers get verified?',
      'a': 'Drivers upload their driver\'s license, vehicle registration papers, and roadworthiness certificate in Verification.'
    },
    {
      'q': 'I was charged the wrong amount',
      'a': 'Select "Payment or refund" above, enter your trip code, and our billing desk will review your receipt.'
    },
  ];

  @override
  void dispose() {
    _tripCodeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (_messageController.text.trim().length < 5) return;
    final randomId = 1000 + Random().nextInt(9000);
    setState(() {
      _caseId = 'CASE-DOGO-$randomId';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      bottomNavigationBar: const RidesBottomNavBar(activeRoute: '/rides/help'),
      body: Column(
        children: [
          const RidesHeaderWidget(activeRoute: '/rides/help'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Title
                      Text(
                        'How can we help?',
                        style: GoogleFonts.sora(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Our customer service team is on standby 24/7 for rides and dispatches.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3 Contact Buttons (Call, WhatsApp, Email)
                      Row(
                        children: [
                          Expanded(
                            child: _buildContactButton(
                              icon: Icons.phone_rounded,
                              label: 'Call us',
                              color: const Color(0xFF2563EB),
                              onTap: () => _launch('tel:+2348000003646'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildContactButton(
                              icon: Icons.chat_rounded,
                              label: 'WhatsApp',
                              color: const Color(0xFF10B981),
                              onTap: () => _launch('https://wa.me/2348000003646'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildContactButton(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              color: const Color(0xFFF5A623),
                              onTap: () => _launch('mailto:support@dogo.ng'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // "Report a problem" Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12151E),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report a problem',
                              style: GoogleFonts.sora(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),

                            if (_caseId != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0x1F10B981),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0x4D10B981)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Report saved: $_caseId',
                                          style: GoogleFonts.sora(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'A support representative has been notified and will reach out promptly.',
                                      style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFFD1D5DB)),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => setState(() {
                                        _caseId = null;
                                        _messageController.clear();
                                        _tripCodeController.clear();
                                      }),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1E2230),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Submit another report'),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Category Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _topics.map((t) {
                                  final isSelected = _selectedTopic == t;
                                  return ChoiceChip(
                                    label: Text(t),
                                    selected: isSelected,
                                    onSelected: (_) => setState(() => _selectedTopic = t),
                                    backgroundColor: const Color(0xFF161922),
                                    selectedColor: const Color(0xFF2563EB).withAlpha(50),
                                    labelStyle: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFF9CA3AF),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isSelected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 16),

                              // Optional Trip Code Input
                              Text(
                                'Trip code (optional)',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _tripCodeController,
                                style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'DG-XXXXXX',
                                  hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF4B5563)),
                                  filled: true,
                                  fillColor: const Color(0xFF161922),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Message Text Area
                              Text(
                                'What happened?',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _messageController,
                                maxLines: 4,
                                style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Describe the issue you experienced...',
                                  hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF4B5563)),
                                  filled: true,
                                  fillColor: const Color(0xFF161922),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              ElevatedButton(
                                onPressed: _submitReport,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Send report',
                                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Common Questions FAQ Accordion
                      Text(
                        'Common questions',
                        style: GoogleFonts.sora(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._faqs.map((faq) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141722),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x1FFFFFFF)),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            collapsedIconColor: const Color(0xFF9CA3AF),
                            iconColor: const Color(0xFF60A5FA),
                            title: Text(
                              faq['q']!,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            children: [
                              Text(
                                faq['a']!,
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: const Color(0xFF9CA3AF),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
