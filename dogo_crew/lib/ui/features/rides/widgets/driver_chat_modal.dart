import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/models/ride_model.dart';

class ChatMessageItem {
  final String id;
  final String text;
  final bool isFromPassenger;
  final DateTime time;

  ChatMessageItem({
    required this.id,
    required this.text,
    required this.isFromPassenger,
    required this.time,
  });
}

class DriverChatModal extends StatefulWidget {
  final RideModel ride;

  const DriverChatModal({super.key, required this.ride});

  static Future<void> show(BuildContext context, RideModel ride) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DriverChatModal(ride: ride),
    );
  }

  @override
  State<DriverChatModal> createState() => _DriverChatModalState();
}

class _DriverChatModalState extends State<DriverChatModal> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<ChatMessageItem> _messages = [];
  bool _isDriverTyping = false;
  Timer? _replyTimer;

  static const List<String> _quickReplies = [
    "I'm at the pickup spot",
    "Coming down in 2 mins",
    "Please call when you arrive",
    "Which vehicle color?",
    "A bit of traffic here",
  ];

  @override
  void initState() {
    super.initState();
    // Default initial greeting from driver
    _messages.addAll([
      ChatMessageItem(
        id: '1',
        text: 'Hello! I have accepted your request and I am en route to ${widget.ride.pickup}.',
        isFromPassenger: false,
        time: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      ChatMessageItem(
        id: '2',
        text: 'Should arrive in about 4-5 minutes.',
        isFromPassenger: false,
        time: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ]);
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    _textCtrl.clear();
    setState(() {
      _messages.add(
        ChatMessageItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: cleanText,
          isFromPassenger: true,
          time: DateTime.now(),
        ),
      );
      _isDriverTyping = true;
    });
    _scrollToBottom();

    // Simulate smart driver response
    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isDriverTyping = false;
        String responseText = "Noted! See you soon.";
        final lower = cleanText.toLowerCase();
        if (lower.contains('color')) {
          responseText = "Vehicle is silver/grey metallic, plate ${widget.ride.driverPlate}. Hazard lights are on.";
        } else if (lower.contains('pickup') || lower.contains('here') || lower.contains('spot')) {
          responseText = "Great! I just pulled up close to the entrance.";
        } else if (lower.contains('coming') || lower.contains('min') || lower.contains('traffic')) {
          responseText = "No problem at all, take your time. I am waiting safe by the curb.";
        } else if (lower.contains('call')) {
          responseText = "Will give you a quick buzz as soon as I halt at the gate.";
        }

        _messages.add(
          ChatMessageItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: responseText,
            isFromPassenger: false,
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  Future<void> _callDriver() async {
    final uri = Uri.parse('tel:${widget.ride.driverPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final ride = widget.ride;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          height: screenHeight * 0.85,
          padding: EdgeInsets.only(bottom: keyboardHeight),
          decoration: const BoxDecoration(
            color: Color(0xFF141722),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0x33FFFFFF), width: 1)),
          ),
          child: Column(
            children: [
              // 1. Header Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 2. Chat Header with Driver Info & Call Action
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x4D2563EB), width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _getInitials(ride.driverName),
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF141722), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ride.driverName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.sora(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0x26F5A623),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF5A623)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${ride.driverRating}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF5A623),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ride.vehicleName} • ${ride.driverPlate}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Call Driver',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      visualDensity: VisualDensity.compact,
                      onPressed: _callDriver,
                      icon: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0x1A2563EB),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: const Color(0x332563EB)),
                        ),
                        child: const Icon(Icons.call_rounded, size: 15, color: Color(0xFF60A5FA)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 20),
                    ),
                  ],
                ),
              ),

              // 3. Quick Replies Pill Bar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quickReplies.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = _quickReplies[idx];
                    return InkWell(
                      onTap: () => _sendMessage(item),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x26FFFFFF)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(color: Color(0x14FFFFFF), height: 1),

              // 4. Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),

              // Typing Indicator
              if (_isDriverTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${ride.driverName.split(' ').first} is typing...',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // 5. Chat Input Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D0F14),
                  border: Border(top: BorderSide(color: Color(0x1FFFFFFF), width: 1)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF141722),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x26FFFFFF)),
                          ),
                          child: TextField(
                            controller: _textCtrl,
                            textInputAction: TextInputAction.send,
                            onSubmitted: _sendMessage,
                            style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Message driver...',
                              hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF6B7280)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _sendMessage(_textCtrl.text),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withAlpha(100),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageItem msg) {
    final timeStr = DateFormat('hh:mm a').format(msg.time);

    return Align(
      alignment: msg.isFromPassenger ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: msg.isFromPassenger
              ? const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: msg.isFromPassenger ? null : const Color(0xFF1F2937),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isFromPassenger ? 16 : 4),
            bottomRight: Radius.circular(msg.isFromPassenger ? 4 : 16),
          ),
          border: msg.isFromPassenger ? null : Border.all(color: const Color(0x1FFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: msg.isFromPassenger ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                color: Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: msg.isFromPassenger ? const Color(0xFF93C5FD) : const Color(0xFF9CA3AF),
                  ),
                ),
                if (msg.isFromPassenger) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, size: 12, color: Color(0xFF93C5FD)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'DR';
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0].substring(0, 1).toUpperCase() : 'DR';
  }
}
