import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/trip_model.dart';
import '../view_models/trip_detail_view_model.dart';

class CancelTripDialog extends StatefulWidget {
  final TripModel trip;
  final TripDetailViewModel viewModel;

  const CancelTripDialog({
    super.key,
    required this.trip,
    required this.viewModel,
  });

  static Future<void> show(BuildContext context, TripModel trip, TripDetailViewModel vm) {
    return showDialog(
      context: context,
      builder: (ctx) => CancelTripDialog(trip: trip, viewModel: vm),
    );
  }

  @override
  State<CancelTripDialog> createState() => _CancelTripDialogState();
}

class _CancelTripDialogState extends State<CancelTripDialog> {
  final _kmController = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  bool get _moved => widget.trip.movedAt != null;
  bool get _isPaid => widget.trip.paymentStatus == 'paid';
  double get _coveredKm => min(
        double.tryParse(_kmController.text) ?? 0.0,
        widget.trip.distanceKm,
      );

  int get _calculatedRefund {
    if (!_isPaid) return 0;
    if (!_moved || _coveredKm <= 0) {
      return (widget.trip.fare * 0.9).floor(); // DOGO keeps 10%
    }
    if (widget.trip.distanceKm > 0) {
      final refund = widget.trip.fare * (1 - _coveredKm / widget.trip.distanceKm);
      return max(0, refund.floor());
    }
    return 0;
  }

  Future<void> _confirmCancel() async {
    setState(() => _isBusy = true);
    try {
      final refund = await widget.viewModel.cancelTrip(_moved ? _coveredKm : 0.0);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPaid
                ? 'Trip cancelled — refund ${CurrencyFormatter.formatNaira(refund)}'
                : 'Trip cancelled',
          ),
          backgroundColor: AppColors.destructive,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel trip.'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Cancel Trip #${widget.trip.code}',
        style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_moved) ...[
              Text(
                'Distance already covered (km of ${widget.trip.distanceKm})',
                style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _kmController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: '0.0',
                  suffixText: 'km',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
            ] else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'The driver has not moved yet. DOGO retains 10% fee; remaining 90% is refunded.',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.goldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: Text(
                _isPaid
                    ? 'Customer refund: ${CurrencyFormatter.formatNaira(_calculatedRefund)} of ${CurrencyFormatter.formatNaira(widget.trip.fare)}'
                    : 'Customer has not paid — nothing to refund.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context),
          child: Text('Keep Trip', style: GoogleFonts.manrope(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          onPressed: _isBusy ? null : _confirmCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.destructive,
            foregroundColor: Colors.white,
          ),
          child: _isBusy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirm Cancel'),
        ),
      ],
    );
  }
}
