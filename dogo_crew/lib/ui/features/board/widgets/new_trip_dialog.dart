import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/repositories/trip_repository.dart';

class NewTripDialog extends StatefulWidget {
  final TripRepository tripRepo;
  final VoidCallback onTripCreated;

  const NewTripDialog({
    super.key,
    required this.tripRepo,
    required this.onTripCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required TripRepository tripRepo,
    required VoidCallback onTripCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: NewTripDialog(
          tripRepo: tripRepo,
          onTripCreated: onTripCreated,
        ),
      ),
    );
  }

  @override
  State<NewTripDialog> createState() => _NewTripDialogState();
}

class _NewTripDialogState extends State<NewTripDialog> {
  final _formKey = GlobalKey<FormState>();
  String _service = 'taxi';
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isPaid = false;
  bool _isSubmitting = false;

  Uint8List? _goodsPhotoBytes;
  String? _goodsPhotoFileName;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _distanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _distance => double.tryParse(_distanceCtrl.text) ?? 0.0;

  int get _fare {
    final rate = AppConstants.ratePerKm[_service] ?? 200;
    return (_distance * rate).round();
  }

  int get _driverShare => (_fare * AppConstants.driverShare).floor();
  int get _dogoShare => _fare - _driverShare;

  Future<void> _pickGoodsPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _goodsPhotoBytes = bytes;
        _goodsPhotoFileName = image.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_service == 'bike' && _goodsPhotoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a picture of the goods to deliver'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.tripRepo.createTrip(
        service: _service,
        customerName: _customerNameCtrl.text.trim(),
        customerPhone: _customerPhoneCtrl.text.trim(),
        pickup: _pickupCtrl.text.trim(),
        dropoff: _dropoffCtrl.text.trim(),
        distanceKm: _distance,
        fare: _fare,
        notes: _notesCtrl.text.trim(),
        isPaid: _isPaid,
        goodsPhotoBytes: _goodsPhotoBytes,
        goodsPhotoFileName: _goodsPhotoFileName,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onTripCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isPaid ? 'Trip posted to drivers' : 'Trip saved — awaiting customer payment'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to post trip. Please try again.'),
          backgroundColor: AppColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Post New Trip',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Service Selector
            Text(
              'Service Type',
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildServiceOption('taxi', 'Taxi', Icons.local_taxi_rounded),
                const SizedBox(width: 8),
                _buildServiceOption('keke', 'Keke', Icons.electric_rickshaw_rounded),
                const SizedBox(width: 8),
                _buildServiceOption('bike', 'Bike', Icons.two_wheeler_rounded),
              ],
            ),
            const SizedBox(height: 16),

            // Customer Name & Phone
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customerNameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Customer Name'),
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _customerPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup & Dropoff
            TextFormField(
              controller: _pickupCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Pickup Location',
                prefixIcon: Icon(Icons.my_location_rounded, size: 18, color: AppColors.brandLight),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dropoffCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Drop-off Destination',
                prefixIcon: Icon(Icons.location_on_rounded, size: 18, color: AppColors.destructive),
              ),
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // Distance & Notes
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _distanceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Distance (km)',
                      suffixText: 'km',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (double.tryParse(v ?? '') == null || (double.tryParse(v ?? '') ?? 0) <= 0)
                        ? 'Valid km'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _notesCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Goods photo for Bike dispatch
            if (_service == 'bike') ...[
              GestureDetector(
                onTap: _pickGoodsPhoto,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _goodsPhotoBytes != null ? AppColors.success : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _goodsPhotoBytes != null ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
                        color: _goodsPhotoBytes != null ? AppColors.success : AppColors.brandLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _goodsPhotoBytes != null ? 'Goods picture attached' : 'Take picture of goods to deliver',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _goodsPhotoBytes != null ? AppColors.success : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pricing Summary Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.goldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_distance km × ${CurrencyFormatter.formatNaira(AppConstants.ratePerKm[_service] ?? 200)}',
                        style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textPrimary),
                      ),
                      Text(
                        CurrencyFormatter.formatNaira(_fare),
                        style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Driver (70%) / DOGO (30%)',
                        style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textMuted),
                      ),
                      Text(
                        '${CurrencyFormatter.formatNaira(_driverShare)} / ${CurrencyFormatter.formatNaira(_dogoShare)}',
                        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Payment checkbox
            CheckboxListTile(
              value: _isPaid,
              onChanged: (v) => setState(() => _isPaid = v ?? false),
              title: Text(
                'Customer has already paid',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.brand,
            ),
            const SizedBox(height: 16),

            // Submit Button
            Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Post Trip',
                        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceOption(String key, String label, IconData icon) {
    final isSelected = _service == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _service = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brand.withAlpha(40) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.brand : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.brandLight : AppColors.textMuted, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
