import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/rides_repository.dart';
import '../../../../data/services/location_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/rides_view_model.dart';
import 'dogo_wallet_modal.dart';

class BookingSheetDialog extends StatefulWidget {
  final bool isDispatch;

  const BookingSheetDialog({
    super.key,
    this.isDispatch = false,
  });

  static Future<void> show(BuildContext context, {bool isDispatch = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingSheetDialog(isDispatch: isDispatch),
    );
  }

  @override
  State<BookingSheetDialog> createState() => _BookingSheetDialogState();
}

class _BookingSheetDialogState extends State<BookingSheetDialog> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _recipientPhoneController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _dropoffFocusNode = FocusNode();

  String? _activeField; // 'pickup' | 'dropoff' | null
  List<LocationPlace> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    final vm = context.read<RidesViewModel>();
    vm.initBooking(isDispatch: widget.isDispatch);
    _pickupController.text = vm.pickup;
    _dropoffController.text = vm.dropoff;

    _pickupFocusNode.addListener(() {
      if (_pickupFocusNode.hasFocus) {
        setState(() {
          _activeField = 'pickup';
        });
        _searchPlaces(_pickupController.text);
      }
    });

    _dropoffFocusNode.addListener(() {
      if (_dropoffFocusNode.hasFocus) {
        setState(() {
          _activeField = 'dropoff';
        });
        _searchPlaces(_dropoffController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    _itemController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  void _searchPlaces(String query) {
    _searchDebounceTimer?.cancel();

    final clean = query.trim().toLowerCase();
    final localMatches = LocationService.predefinedPlaces.where((p) {
      if (clean.isEmpty) return true;
      return p.title.toLowerCase().contains(clean) ||
          p.subtitle.toLowerCase().contains(clean);
    }).take(7).toList();

    setState(() {
      _suggestions = localMatches;
      _isLoadingSuggestions = clean.isNotEmpty;
    });

    if (clean.isEmpty) {
      _isLoadingSuggestions = false;
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await LocationService.searchLocations(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoadingSuggestions = false;
        });
      }
    });
  }

  void _selectPlace(LocationPlace place, RidesViewModel vm, bool isPickup) {
    if (isPickup) {
      vm.setPickup(place.displayName, coord: place.coordinates);
      _pickupController.text = place.displayName;
      _pickupFocusNode.unfocus();
    } else {
      vm.setDropoff(place.displayName, coord: place.coordinates);
      _dropoffController.text = place.displayName;
      _dropoffFocusNode.unfocus();
    }
    setState(() {
      _activeField = null;
    });
  }

  Future<void> _useCurrentGps(RidesViewModel vm) async {
    final place = await vm.useCurrentGpsAsPickup();
    if (place != null) {
      _pickupController.text = place.displayName;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pickup set to ${place.title}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RidesViewModel>();
    final isDispatch = widget.isDispatch;
    final step = vm.bookingStep;
    final fare = vm.currentFare;
    final formattedFare = '₦${NumberFormat('#,###').format(fare)}';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF10131B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0x33FFFFFF), width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDispatch ? 'Send a package' : 'Book a ride',
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepSubtitle(step, isDispatch),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 14),

                // Step progress bar
                Row(
                  children: List.generate(3, (index) {
                    final isDone = index <= step;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFF2563EB) : const Color(0x22FFFFFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0x14FFFFFF), height: 1),

          // Body Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildStepContent(context, vm, step, isDispatch),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0C0E14),
              border: Border(
                top: BorderSide(color: Color(0x1AFFFFFF), width: 1),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Estimated fare',
                      style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF)),
                    ),
                    Text(
                      formattedFare,
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF5A623),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (step > 0) ...[
                            OutlinedButton(
                              onPressed: () => vm.setBookingStep(step - 1),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0x2EFFFFFF)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: Text('Back', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            onPressed: () {
                              if (step < 2) {
                                vm.setBookingStep(step + 1);
                              } else {
                                if (vm.selectedPaymentId == 'wallet' && !vm.hasSufficientWalletBalance) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Insufficient wallet balance. Please top up to confirm ride.'),
                                      backgroundColor: Color(0xFFEF4444),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  DogoWalletModal.show(context, openFund: true);
                                  return;
                                }
                                if (isDispatch) {
                                  vm.setDispatchInfo(
                                    name: _recipientNameController.text.trim(),
                                    phone: _recipientPhoneController.text.trim(),
                                    item: _itemController.text.trim(),
                                  );
                                }
                                String pName = 'Salim Abdulaziz';
                                String? pPhone;
                                try {
                                  final authVm = context.read<AuthViewModel>();
                                  if (authVm.displayName.isNotEmpty) {
                                    pName = authVm.displayName;
                                  }
                                  pPhone = authVm.phone;
                                } catch (_) {}
                                final newRide = vm.confirmBooking(
                                  passengerName: pName,
                                  passengerPhone: pPhone,
                                );
                                Navigator.of(context).pop();
                                context.push('/rides/track/${newRide.code}');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  step < 2 ? 'Next' : (isDispatch ? 'Send package' : 'Confirm ride'),
                                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  String _getStepSubtitle(int step, bool isDispatch) {
    if (isDispatch) {
      return ['Where should it go?', 'Your bike dispatcher', 'Recipient and payment'][step];
    }
    return ['Where are you going?', 'Choose your ride', 'Review your trip'][step];
  }

  Widget _buildStepContent(BuildContext context, RidesViewModel vm, int step, bool isDispatch) {
    switch (step) {
      case 0:
        return _buildStep0Route(context, vm, isDispatch);
      case 1:
        return _buildStep1Vehicle(context, vm, isDispatch);
      case 2:
        return _buildStep2Review(context, vm, isDispatch);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLocationInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    required Color iconColor,
    required bool isActive,
    required VoidCallback onClear,
    required ValueChanged<String> onChanged,
    Widget? trailingAction,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? iconColor : const Color(0x24FFFFFF),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.manrope(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onChanged: onChanged,
              onSubmitted: (val) {
                focusNode.unfocus();
                setState(() => _activeField = null);
              },
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
              ),
            ),
          ?trailingAction,
        ],
      ),
    );
  }

  Widget _buildSuggestionList(bool isPickup, RidesViewModel vm) {
    final currentText = isPickup ? _pickupController.text : _dropoffController.text;

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141824),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x332563EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(102),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPickup) ...[
            InkWell(
              onTap: () async {
                await _useCurrentGps(vm);
                setState(() => _activeField = null);
                _pickupFocusNode.unfocus();
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
                  color: Color(0x1F10B981),
                ),
                child: Row(
                  children: [
                    vm.isLocatingPickup
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                          )
                        : const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use current GPS location',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            'Auto-detect address via device GPS',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: const Color(0xFF6EE7B7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF10B981)),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentText.trim().isEmpty ? 'POPULAR DESTINATIONS' : 'SEARCH RESULTS',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 0.8,
                  ),
                ),
                if (_isLoadingSuggestions)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF2563EB)),
                  ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: _suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'No matching places found',
                      style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, _) => const Divider(color: Color(0x12FFFFFF), height: 1),
                    itemBuilder: (context, index) {
                      final place = _suggestions[index];
                      return InkWell(
                        onTap: () => _selectPlace(place, vm, isPickup),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 16, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.title,
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (place.subtitle.isNotEmpty)
                                      Text(
                                        place.subtitle,
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: const Color(0xFF9CA3AF),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (currentText.trim().isNotEmpty &&
              !_suggestions.any((s) => s.title.toLowerCase() == currentText.trim().toLowerCase())) ...[
            const Divider(color: Color(0x1AFFFFFF), height: 1),
            InkWell(
              onTap: () {
                final customPlace = LocationPlace(
                  title: currentText.trim(),
                  subtitle: 'Custom Location',
                  coordinates: LocationService.getCoordinates(currentText.trim()),
                );
                _selectPlace(customPlace, vm, isPickup);
              },
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.add_location_alt_outlined, size: 16, color: Color(0xFF60A5FA)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Use "$currentText" as custom address',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF93C5FD),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep0Route(BuildContext context, RidesViewModel vm, bool isDispatch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pickup Point with GPS auto-detect
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pick-up point',
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFD1D5DB)),
            ),
            InkWell(
              onTap: vm.isLocatingPickup ? null : () => _useCurrentGps(vm),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (vm.isLocatingPickup)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF10B981)),
                      )
                    else
                      const Icon(Icons.my_location_rounded, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      vm.isLocatingPickup ? 'Locating...' : 'Use current GPS',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildLocationInputField(
          controller: _pickupController,
          focusNode: _pickupFocusNode,
          hintText: 'Search pick-up location...',
          icon: Icons.my_location_rounded,
          iconColor: const Color(0xFF10B981),
          isActive: _activeField == 'pickup',
          onClear: () {
            _pickupController.clear();
            _searchPlaces('');
          },
          onChanged: (val) {
            _searchPlaces(val);
          },
          trailingAction: IconButton(
            icon: const Icon(Icons.gps_fixed_rounded, size: 16, color: Color(0xFF10B981)),
            tooltip: 'Use current GPS',
            onPressed: () => _useCurrentGps(vm),
            splashRadius: 16,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ),

        if (_activeField == 'pickup')
          _buildSuggestionList(true, vm),

        const SizedBox(height: 14),

        // Dropoff Point
        Text(
          isDispatch ? 'Delivery destination' : 'Where to?',
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFD1D5DB)),
        ),
        const SizedBox(height: 6),
        _buildLocationInputField(
          controller: _dropoffController,
          focusNode: _dropoffFocusNode,
          hintText: isDispatch ? 'Search delivery address...' : 'Where are you going?',
          icon: Icons.location_on_rounded,
          iconColor: const Color(0xFFF5A623),
          isActive: _activeField == 'dropoff',
          onClear: () {
            _dropoffController.clear();
            _searchPlaces('');
          },
          onChanged: (val) {
            _searchPlaces(val);
          },
        ),

        if (_activeField == 'dropoff')
          _buildSuggestionList(false, vm),

        // Quick City Suggestion Chips
        if (_activeField != 'dropoff') ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              'Lekki Phase 1',
              'Ikeja GRA',
              'Victoria Island',
              'Airport (MMA2)',
              'Yaba',
              'Bodija',
            ].map((name) {
              final isSelected = vm.dropoff.toLowerCase().contains(name.toLowerCase());
              return ChoiceChip(
                label: Text(name),
                selected: isSelected,
                onSelected: (_) {
                  final place = LocationService.predefinedPlaces.firstWhere(
                    (p) => p.title.toLowerCase().contains(name.toLowerCase()),
                    orElse: () => LocationPlace(
                      title: name,
                      subtitle: 'Nigeria',
                      coordinates: LocationService.getCoordinates(name),
                    ),
                  );
                  vm.setDropoff(place.displayName, coord: place.coordinates);
                  _dropoffController.text = place.displayName;
                  setState(() => _activeField = null);
                },
                backgroundColor: const Color(0xFF161922),
                selectedColor: const Color(0xFF2563EB).withAlpha(50),
                labelStyle: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFF9CA3AF),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF)),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 20),

        // Ride now vs Later Toggle
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => vm.setScheduled(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !vm.isScheduled ? const Color(0xFF2563EB) : const Color(0xFF161922),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !vm.isScheduled ? const Color(0xFF2563EB) : const Color(0x22FFFFFF),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isDispatch ? 'Send now' : 'Ride now',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => vm.setScheduled(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: vm.isScheduled ? const Color(0xFF2563EB) : const Color(0xFF161922),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: vm.isScheduled ? const Color(0xFF2563EB) : const Color(0x22FFFFFF),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Later',
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
            ),
          ],
        ),

        // Scheduled Date & Time Pickers
        if (vm.isScheduled) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      vm.setScheduledDateTime(picked, vm.scheduledTime ?? const TimeOfDay(hour: 9, minute: 0));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161922),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: Text(
                      vm.scheduledDate != null
                          ? DateFormat('EEE, MMM d').format(vm.scheduledDate!)
                          : 'Select date',
                      style: GoogleFonts.manrope(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (picked != null) {
                      vm.setScheduledDateTime(vm.scheduledDate ?? DateTime.now(), picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161922),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: Text(
                      vm.scheduledTime != null
                          ? '${vm.scheduledTime!.hour.toString().padLeft(2, '0')}:${vm.scheduledTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select time',
                      style: GoogleFonts.manrope(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x1F2563EB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x332563EB)),
          ),
          child: Row(
            children: [
              const Icon(Icons.route_rounded, size: 16, color: Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Text(
                'Estimated distance: ',
                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
              ),
              Text(
                '${vm.currentDistance} km',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Vehicle(BuildContext context, RidesViewModel vm, bool isDispatch) {
    final availableVehicles = RidesRepository.vehicles
        .where((v) => isDispatch ? v.service == 'dispatch' : v.service == 'ride')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDispatch ? 'Select dispatch courier' : 'Choose your ride type',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 12),
        ...availableVehicles.map((option) {
          final isSelected = vm.selectedVehicleId == option.id;
          final optionFare = vm.ridesRepo.calculateFare(option, vm.currentDistance);
          final formattedOptionFare = '₦${NumberFormat('#,###').format(optionFare)}';

          return GestureDetector(
            onTap: () => vm.setVehicleId(option.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF131722) : const Color(0xFF161922),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0x1AFFFFFF),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withAlpha(40),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0E14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    alignment: Alignment.center,
                    child: Text(option.icon, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.name,
                          style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${option.capacity} • ${option.eta}',
                          style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formattedOptionFare,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF5A623),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          'Fares shown are transparent estimates calculated for your selected route.',
          style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildStep2Review(BuildContext context, RidesViewModel vm, bool isDispatch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161922),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${vm.pickup} → ${vm.dropoff}',
                      style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${vm.currentVehicle.name} • ${vm.currentDistance} km ${vm.isScheduled ? "• Scheduled trip" : "• Ride now"}',
                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0x1FFFFFFF), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated fare',
                    style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
                  ),
                  Text(
                    '₦${NumberFormat('#,###').format(vm.currentFare)}',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF5A623),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Dispatch Item & Recipient Inputs
        if (isDispatch) ...[
          const SizedBox(height: 16),
          Text(
            'Package & Recipient Details',
            style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _itemController,
            label: 'What are you sending?',
            hint: 'e.g. Documents, food, spare parts',
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _recipientNameController,
            label: 'Recipient name',
            hint: 'Full name',
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _recipientPhoneController,
            label: 'Recipient phone number',
            hint: '080...',
            keyboardType: TextInputType.phone,
          ),
        ],

        const SizedBox(height: 18),

        // Payment Method Selection
        Text(
          'Payment method',
          style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 8),
        ...RidesRepository.paymentMethods.map((method) {
          final isSelected = vm.selectedPaymentId == method.id;
          return GestureDetector(
            onTap: () => vm.setPaymentId(method.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF141824) : const Color(0xFF161922),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0x1AFFFFFF),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    method.id == 'wallet'
                        ? Icons.account_balance_wallet_outlined
                        : (method.id == 'card' ? Icons.credit_card_outlined : Icons.currency_bitcoin_rounded),
                    size: 18,
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.label,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          method.id == 'wallet'
                              ? 'Balance ${vm.formattedWalletBalance}${!vm.hasSufficientWalletBalance ? ' (Low)' : ''}'
                              : method.hint,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: method.id == 'wallet' ? FontWeight.w600 : FontWeight.normal,
                            color: method.id == 'wallet'
                                ? (vm.hasSufficientWalletBalance ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (method.id == 'wallet')
                    GestureDetector(
                      onTap: () => DogoWalletModal.show(context, openFund: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x242563EB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x662563EB)),
                        ),
                        child: Text(
                          '+ Top up',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF93C5FD),
                          ),
                        ),
                      ),
                    ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF4B5563)),
            filled: true,
            fillColor: const Color(0xFF161922),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0x22FFFFFF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0x22FFFFFF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
      ],
    );
  }
}
