import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/view_models/auth_view_model.dart';

class DriverClearanceScreen extends StatefulWidget {
  const DriverClearanceScreen({super.key});

  @override
  State<DriverClearanceScreen> createState() => _DriverClearanceScreenState();
}

class _DriverClearanceScreenState extends State<DriverClearanceScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedVehicleType = 'taxi'; // 'taxi', 'keke', 'bike'
  final _makeModelController = TextEditingController(text: 'Toyota Corolla 2018 (Silver)');
  final _plateController = TextEditingController(text: 'LAG-605-EK');
  final _licenseController = TextEditingController(text: 'DL-90821-LG');
  final _guarantorController = TextEditingController(text: '+234 802 000 1122');

  @override
  void initState() {
    super.initState();
    final authVm = context.read<AuthViewModel>();
    if (authVm.vehicle != null && authVm.vehicle!.isNotEmpty) {
      _makeModelController.text = authVm.vehicle!;
    }
    if (authVm.plate != null && authVm.plate!.isNotEmpty) {
      _plateController.text = authVm.plate!;
    }
    if (authVm.driverVehicleType != null) {
      _selectedVehicleType = authVm.driverVehicleType!;
    }
    if (authVm.driverLicenseNumber != null && authVm.driverLicenseNumber!.isNotEmpty) {
      _licenseController.text = authVm.driverLicenseNumber!;
    }
  }

  @override
  void dispose() {
    _makeModelController.dispose();
    _plateController.dispose();
    _licenseController.dispose();
    _guarantorController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication(AuthViewModel authVm) async {
    if (!_formKey.currentState!.validate()) return;

    await authVm.submitDriverClearance(
      vehicleType: _selectedVehicleType,
      vehicleModel: _makeModelController.text.trim(),
      plateNumber: _plateController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      guarantorPhone: _guarantorController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clearance application submitted successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final status = authVm.driverClearanceStatus; // 'not_applied', 'pending', 'active'

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
          'Driver Clearance',
          style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: _buildBodyForStatus(context, authVm, status),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyForStatus(BuildContext context, AuthViewModel authVm, String status) {
    if (status == 'active') {
      return _buildApprovedView(context, authVm);
    } else if (status == 'pending') {
      return _buildPendingView(context, authVm);
    } else {
      return _buildApplicationForm(context, authVm);
    }
  }

  // 1. APPROVED VIEW
  Widget _buildApprovedView(BuildContext context, AuthViewModel authVm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x3310B981)),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0x1F10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_rounded, size: 40, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 18),
              Text(
                'Driver Clearance Approved!',
                style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your documents and vehicle credentials have been verified by DOGO Operations. You are cleared to accept rides and deliveries.',
                style: GoogleFonts.manrope(fontSize: 13.5, color: const Color(0xFF9CA3AF), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Clearance details summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F121B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Captain Name', authVm.displayName),
                    const Divider(color: Color(0x14FFFFFF), height: 16),
                    _buildDetailRow('Vehicle', authVm.vehicle ?? 'Toyota Corolla (White)'),
                    const Divider(color: Color(0x14FFFFFF), height: 16),
                    _buildDetailRow('License Plate', authVm.plate ?? 'LAG-605-EK'),
                    const Divider(color: Color(0x14FFFFFF), height: 16),
                    _buildDetailRow('License Number', authVm.driverLicenseNumber ?? 'DL-90821-LG'),
                    const Divider(color: Color(0x14FFFFFF), height: 16),
                    _buildDetailRow('Clearance Status', 'Active & Cleared', color: const Color(0xFF10B981)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/board'),
            icon: const Icon(Icons.local_taxi_rounded, size: 20),
            label: Text(
              'Open Captain Console',
              style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // 2. PENDING VIEW
  Widget _buildPendingView(BuildContext context, AuthViewModel authVm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x33F59E0B)),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0x1FF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 36, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 18),
              Text(
                'Clearance Under Review',
                style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your driver clearance application has been submitted to DOGO Operations. Review typically completes within 24 to 48 hours.',
                style: GoogleFonts.manrope(fontSize: 13.5, color: const Color(0xFF9CA3AF), height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Application Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F121B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Applicant', authVm.displayName),
                    const Divider(color: Color(0x14FFFFFF), height: 16),
                    _buildDetailRow('Vehicle Model', authVm.vehicle ?? _makeModelController.text),
                    const Divider(color: Color(0x14FFFFFF), height: 16),
                    _buildDetailRow('Plate Number', authVm.plate ?? _plateController.text),
                    const Divider(color: Color(0x14FFFFFF), height: 16),
                    _buildDetailRow('Vetting Status', 'Under Review', color: const Color(0xFFF59E0B)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Testing fast-track bypass button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x142563EB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x332563EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.developer_mode_rounded, size: 18, color: Color(0xFF60A5FA)),
                  const SizedBox(width: 8),
                  Text(
                    'Testing / Review Mode',
                    style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF60A5FA)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'You can instantly approve this clearance to test the Captain Console and live dispatch without waiting.',
                style: GoogleFonts.manrope(fontSize: 12.5, color: const Color(0xFF93C5FD)),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () async {
                  await authVm.approveDriverClearance();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Clearance approved! Welcome to DOGO Captains.'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Instant Clearance Approval (Demo)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. APPLICATION FORM
  Widget _buildApplicationForm(BuildContext context, AuthViewModel authVm) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner intro
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF141722), Color(0xFF1B2030)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x1FFFFFFF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0x1F10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.badge_outlined, color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earn with DOGO',
                        style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep 85% of trip fares. Weekly payouts and daily bonuses across Nigeria.',
                        style: GoogleFonts.manrope(fontSize: 12.5, color: const Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Vehicle Type Selector
          Text(
            'Vehicle Type',
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildVehicleTypeChip('taxi', 'Car / Taxi', Icons.local_taxi_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVehicleTypeChip('keke', 'Keke Tricycle', Icons.electric_rickshaw_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVehicleTypeChip('bike', 'Courier Bike', Icons.two_wheeler_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vehicle Make & Model
          _buildInputLabel('Vehicle Make, Model & Color'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _makeModelController,
            hintText: 'e.g., Toyota Corolla 2018 (Silver)',
            icon: Icons.directions_car_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter vehicle details' : null,
          ),
          const SizedBox(height: 16),

          // License Plate Number
          _buildInputLabel('License Plate Number'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _plateController,
            hintText: 'e.g., LAG-605-EK',
            icon: Icons.pin_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter license plate' : null,
          ),
          const SizedBox(height: 16),

          // Driver's License Number
          _buildInputLabel('Driver\'s License Number'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _licenseController,
            hintText: 'e.g., DL-90821-LG',
            icon: Icons.credit_card_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter license number' : null,
          ),
          const SizedBox(height: 16),

          // Guarantor Phone
          _buildInputLabel('Next of Kin / Guarantor Phone'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _guarantorController,
            hintText: '+234 800 000 0000',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 28),

          // Submit Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: authVm.isLoading ? null : () => _submitApplication(authVm),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: authVm.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Submit for Driver Clearance',
                      style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedVehicleType == type;
    return InkWell(
      onTap: () => setState(() => _selectedVehicleType = type),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1F2563EB) : const Color(0xFF141722),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.manrope(fontSize: 14, color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFF141722),
        hintText: hintText,
        hintStyle: GoogleFonts.manrope(fontSize: 13.5, color: const Color(0xFF4B5563)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
