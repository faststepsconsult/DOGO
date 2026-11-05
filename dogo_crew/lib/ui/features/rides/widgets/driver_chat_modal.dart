import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/ride_model.dart';
import '../../../../data/models/trip_message_model.dart';
import '../../../../data/services/audio_cues_service.dart';
import '../../../../data/services/in_app_call_service.dart';
import '../../../../data/services/trip_chat_service.dart';
import '../../../core/widgets/in_app_call_modal.dart';

class DriverChatModal extends StatefulWidget {
  final String tripCode;
  final String contactName;
  final String contactSubtitle;
  final String contactPhone;
  final bool isDriverMode;

  const DriverChatModal({
    super.key,
    required this.tripCode,
    required this.contactName,
    required this.contactSubtitle,
    required this.contactPhone,
    this.isDriverMode = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String tripCode,
    required String contactName,
    required String contactSubtitle,
    required String contactPhone,
    bool isDriverMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DriverChatModal(
        tripCode: tripCode,
        contactName: contactName,
        contactSubtitle: contactSubtitle,
        contactPhone: contactPhone,
        isDriverMode: isDriverMode,
      ),
    );
  }

  static Future<void> showForRide(
    BuildContext context,
    RideModel ride, {
    bool isDriverMode = false,
  }) {
    final contactName = isDriverMode
        ? (ride.passengerName.isNotEmpty ? ride.passengerName : 'Passenger')
        : (ride.driverName.isNotEmpty ? ride.driverName : 'Driver');
    final contactSubtitle = isDriverMode
        ? '${ride.pickup} → ${ride.dropoff}'
        : '${ride.vehicleName} • ${ride.driverPlate}';
    final contactPhone = isDriverMode ? ride.passengerPhone : ride.driverPhone;

    return show(
      context,
      tripCode: ride.code,
      contactName: contactName,
      contactSubtitle: contactSubtitle,
      contactPhone: contactPhone,
      isDriverMode: isDriverMode,
    );
  }

  @override
  State<DriverChatModal> createState() => _DriverChatModalState();
}

class _DriverChatModalState extends State<DriverChatModal> {
  final TripChatService _chatService = TripChatService();
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  StreamSubscription<List<TripMessageModel>>? _messagesSub;
  StreamSubscription<bool>? _typingSub;
  List<TripMessageModel> _messages = [];
  bool _isOtherTyping = false;
  Timer? _typingDebounce;

  static const List<String> _passengerQuickReplies = [
    "I'm at the pickup spot",
    "Coming down in 2 mins",
    "Please call when you arrive",
    "Which vehicle color?",
    "Waiting by the entrance",
  ];

  static const List<String> _driverQuickReplies = [
    "I'm on my way",
    "Arrived at the pickup point",
    "Hazard lights are on",
    "Waiting outside the gate",
    "A bit of traffic, almost there",
  ];

  String get _currentRole => widget.isDriverMode ? 'driver' : 'passenger';
  String get _otherRole => widget.isDriverMode ? 'passenger' : 'driver';

  @override
  void initState() {
    super.initState();
    _chatService.setModalOpen(widget.tripCode, true, _currentRole);
    _messages = _chatService.getMessages(widget.tripCode);
    int previousCount = _messages.length;

    _messagesSub = _chatService.streamMessages(widget.tripCode).listen((list) {
      if (mounted) {
        if (list.length > previousCount) {
          final last = list.last;
          if (last.senderKind != _currentRole) {
            AudioCuesService.instance.playChatMessage();
          }
        }
        previousCount = list.length;
        setState(() {
          _messages = list;
        });
        _scrollToBottom();
      }
    });

    _typingSub = _chatService.streamTyping(widget.tripCode, _otherRole).listen((isTyping) {
      if (mounted) {
        setState(() {
          _isOtherTyping = isTyping;
        });
        if (isTyping) _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _messagesSub?.cancel();
    _typingSub?.cancel();
    _chatService.setModalOpen(widget.tripCode, false, _currentRole);
    _chatService.sendTyping(
      tripCode: widget.tripCode,
      isTyping: false,
      senderRole: _currentRole,
    );
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

  void _onTextChanged(String val) {
    _typingDebounce?.cancel();
    _chatService.sendTyping(
      tripCode: widget.tripCode,
      isTyping: val.trim().isNotEmpty,
      senderRole: _currentRole,
    );

    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _chatService.sendTyping(
        tripCode: widget.tripCode,
        isTyping: false,
        senderRole: _currentRole,
      );
    });
  }

  void _sendMessage(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _textCtrl.clear();
    _typingDebounce?.cancel();
    _chatService.sendTyping(
      tripCode: widget.tripCode,
      isTyping: false,
      senderRole: _currentRole,
    );

    _chatService.sendMessage(
      tripCode: widget.tripCode,
      body: clean,
      senderRole: _currentRole,
    );
    // Mark in-app contact attempted for anti-fraud proof
    InAppCallService.instance.recordContactAttempt(widget.tripCode);
    _scrollToBottom();
  }

  Future<void> _callContact() async {
    final cleanPhone = widget.contactPhone.replaceAll(' ', '');
    final myRole = widget.isDriverMode ? 'driver' : 'passenger';
    final peerRole = widget.isDriverMode ? 'Passenger' : 'Captain';

    // 1. In-App Data Call (VoIP over Mobile Data - 0 airtime)
    await InAppCallService.instance.startOutgoingCall(
      rideCode: widget.tripCode,
      peerName: widget.contactName,
      peerRole: peerRole,
      peerPhone: cleanPhone,
      myRole: myRole,
      simulateAnswerForDemo: true,
    );

    if (mounted) {
      InAppCallModal.show(context, InAppCallService.instance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final quickReplies = widget.isDriverMode ? _driverQuickReplies : _passengerQuickReplies;

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

              // 2. Chat Header
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
                            gradient: LinearGradient(
                              colors: widget.isDriverMode
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isDriverMode
                                  ? const Color(0x4D10B981)
                                  : const Color(0x4D2563EB),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _getInitials(widget.contactName),
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
                                  widget.contactName,
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: widget.isDriverMode
                                      ? const Color(0x2610B981)
                                      : const Color(0x262563EB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.isDriverMode ? 'Passenger' : 'Driver',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isDriverMode
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF60A5FA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.contactSubtitle,
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
                    if (widget.contactPhone.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Call',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        visualDensity: VisualDensity.compact,
                        onPressed: _callContact,
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0x1A10B981),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: const Color(0x3310B981)),
                          ),
                          child: const Icon(Icons.call_rounded, size: 15, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
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

              // 3. Quick Replies Bar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: quickReplies.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = quickReplies[idx];
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

              // 4. Messages Stream
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 40,
                              color: Colors.white.withAlpha(40),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chatting live for trip ${widget.tripCode}',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Messages are delivered in real time.',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderKind == _currentRole;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
              ),

              // Typing Indicator
              if (_isOtherTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.contactName.split(' ').first} is typing...',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // 5. Input Field
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
                            onChanged: _onTextChanged,
                            onSubmitted: _sendMessage,
                            style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
                            decoration: InputDecoration(
                              hintText: widget.isDriverMode
                                  ? 'Message passenger...'
                                  : 'Message driver...',
                              hintStyle: GoogleFonts.manrope(
                                fontSize: 13,
                                color: const Color(0xFF6B7280),
                              ),
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
                            gradient: LinearGradient(
                              colors: widget.isDriverMode
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (widget.isDriverMode
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF2563EB))
                                    .withAlpha(100),
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

  Widget _buildMessageBubble(TripMessageModel msg, bool isMe) {
    final timeStr = DateFormat('hh:mm a').format(msg.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: widget.isDriverMode
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : const Color(0xFF1F2937),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: const Color(0x1FFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              msg.body,
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
                    color: isMe ? const Color(0xFFD1FAE5) : const Color(0xFF9CA3AF),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, size: 12, color: Color(0xFFD1FAE5)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return widget.isDriverMode ? 'PA' : 'DR';
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0].substring(0, 1).toUpperCase() : (widget.isDriverMode ? 'PA' : 'DR');
  }
}
