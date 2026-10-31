import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/crew_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/trip_detail_view_model.dart';
import '../widgets/cancel_trip_dialog.dart';

class TripDetailScreen extends StatelessWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => TripDetailViewModel(
        tripId: tripId,
        tripRepo: ctx.read<TripRepository>(),
        chatRepo: ctx.read<ChatRepository>(),
        crewRepo: ctx.read<CrewRepository>(),
      ),
      child: const _TripDetailContent(),
    );
  }
}

class _TripDetailContent extends StatefulWidget {
  const _TripDetailContent();

  @override
  State<_TripDetailContent> createState() => _TripDetailContentState();
}

class _TripDetailContentState extends State<_TripDetailContent> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  static const List<String> _quickReplies = [
    "I'm on my way 🚗",
    "I've arrived at pickup",
    "Running 5 mins late, sorry",
    "Please confirm your exact location",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _launchUrlString(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TripDetailViewModel>();
    final authVm = context.watch<AuthViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }

    final trip = vm.trip;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: const Center(child: Text('Trip not found or not assigned to you.')),
      );
    }

    final isDispatcher = authVm.isDispatcher;
    final currentUserId = authVm.currentUser?.id;
    final canAct = isDispatcher || trip.assignedTo == currentUserId;
    final nextInfo = AppConstants.nextStatus[trip.status];

    // Scroll chat on new messages
    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '#${trip.code}',
          style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Overview Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          StatusBadge.service(trip.service),
                          StatusBadge.tripStatus(trip.status),
                        ],
                      ),
                      StatusBadge.payment(trip.paymentStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyFormatter.formatNaira(trip.fare),
                    style: GoogleFonts.sora(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip.distanceKm > 0 ? '${trip.distanceKm} km · ' : ''}Driver gets ${CurrencyFormatter.formatNaira(trip.driverShare)} (70%)',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (trip.refundAmount != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.destructiveBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.destructiveBorder),
                      ),
                      child: Text(
                        'Refunded ${CurrencyFormatter.formatNaira(trip.refundAmount!)} to customer · ${trip.distanceCoveredKm != null ? '${trip.distanceCoveredKm} km covered' : 'driver had not moved (10% fee retained)'}',
                        style: GoogleFonts.manrope(fontSize: 12, color: AppColors.destructive),
                      ),
                    ),
                  ],
                  const Divider(color: AppColors.border, height: 28),
                  _buildLocationRow('Pickup', trip.pickup, Icons.radio_button_checked, AppColors.brandLight),
                  const SizedBox(height: 12),
                  _buildLocationRow('Drop-off', trip.dropoff, Icons.location_on, AppColors.destructive),
                  if (trip.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.goldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.goldBorder),
                      ),
                      child: Text(
                        'Note: ${trip.notes}',
                        style: GoogleFonts.manrope(fontSize: 12, color: AppColors.gold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Customer Contact Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CUSTOMER',
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trip.customerName,
                    style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.call_rounded, size: 16),
                          label: const Text('Call'),
                          onPressed: () => _launchUrlString('tel:${trip.customerPhone}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.sms_rounded, size: 16),
                          label: const Text('SMS'),
                          onPressed: () => _launchUrlString('sms:${trip.customerPhone}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat_rounded, size: 16),
                          label: const Text('WhatsApp'),
                          onPressed: () {
                            final cleanPhone = trip.customerPhone.replaceAll(RegExp(r'\D'), '');
                            _launchUrlString('https://wa.me/$cleanPhone');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Goods Photo (if available)
            if (vm.goodsPhotoSignedUrl != null) ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GOODS TO DELIVER',
                      style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        vm.goodsPhotoSignedUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 4. Action Controls (Status, Assign Driver, Mark Paid, Cancel)
            if (canAct)
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDispatcher && trip.paymentStatus == 'unpaid') ...[
                      ElevatedButton(
                        onPressed: () async {
                          final ok = await vm.markPaid();
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Payment recorded'), backgroundColor: AppColors.success),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        child: const Text('Customer has paid'),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (nextInfo != null && trip.paymentStatus == 'paid') ...[
                      ElevatedButton(
                        onPressed: () => vm.advanceStatus(nextInfo['to']!),
                        child: Text(nextInfo['label']!),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (isDispatcher && trip.paymentStatus == 'paid') ...[
                      DropdownButtonFormField<String>(
                        initialValue: trip.assignedTo,
                        hint: const Text('Assign a driver'),
                        dropdownColor: AppColors.surfaceElevated,
                        items: vm.drivers.map((d) {
                          return DropdownMenuItem(value: d.id, child: Text(d.fullName));
                        }).toList(),
                        onChanged: (driverId) {
                          if (driverId != null) vm.assignDriver(driverId);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (!['completed', 'cancelled'].contains(trip.status))
                      TextButton(
                        onPressed: () => CancelTripDialog.show(context, trip, vm),
                        child: Text(
                          'Cancel trip',
                          style: GoogleFonts.manrope(
                            color: AppColors.destructive,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // 5. Live Conversation
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversation',
                          style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Messages with ${trip.customerName}, shared with dispatchers.',
                          style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),

                  // Message bubbles
                  Container(
                    height: 240,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: vm.messages.isEmpty
                        ? Center(
                            child: Text(
                              'No messages yet.',
                              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textMuted),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: vm.messages.length,
                            itemBuilder: (context, index) {
                              final msg = vm.messages[index];
                              final fromCustomer = msg.senderKind != 'staff';
                              final isMe = msg.senderId == currentUserId && !fromCustomer;

                              return Align(
                                alignment: fromCustomer ? Alignment.centerLeft : Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  decoration: BoxDecoration(
                                    color: fromCustomer ? AppColors.surfaceLight : AppColors.brand,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: fromCustomer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        fromCustomer ? trip.customerName : (isMe ? 'You' : 'Crew'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withAlpha(160),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        msg.body,
                                        style: const TextStyle(fontSize: 14, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Quick reply chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: _quickReplies.map((reply) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(reply, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppColors.surfaceLight,
                            side: const BorderSide(color: AppColors.border),
                            onPressed: () {
                              if (currentUserId != null) {
                                vm.sendMessage(body: reply, senderId: currentUserId);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Chat Input Field
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Type a message…',
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty && currentUserId != null) {
                                vm.sendMessage(body: val, senderId: currentUserId);
                                _messageController.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppColors.brandLight),
                          onPressed: () {
                            final text = _messageController.text;
                            if (text.trim().isNotEmpty && currentUserId != null) {
                              vm.sendMessage(body: text, senderId: currentUserId);
                              _messageController.clear();
                            }
                          },
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
    );
  }

  Widget _buildLocationRow(String label, String address, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.manrope(fontSize: 11, color: AppColors.textMuted),
              ),
              Text(
                address,
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
