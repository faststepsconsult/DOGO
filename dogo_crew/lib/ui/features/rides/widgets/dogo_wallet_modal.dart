import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/wallet_transaction_model.dart';
import '../view_models/rides_view_model.dart';

enum _WalletViewMode { overview, fund, bankDetails }

class DogoWalletModal extends StatefulWidget {
  final bool initialOpenFund;

  const DogoWalletModal({super.key, this.initialOpenFund = false});

  static Future<void> show(BuildContext context, {bool openFund = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DogoWalletModal(initialOpenFund: openFund),
    );
  }

  @override
  State<DogoWalletModal> createState() => _DogoWalletModalState();
}

class _DogoWalletModalState extends State<DogoWalletModal> {
  late _WalletViewMode _viewMode;
  final TextEditingController _amountController = TextEditingController(text: '5000');
  int _selectedPresetAmount = 5000;
  String _selectedFundingMethod = 'card'; // 'card', 'bank', 'ussd'
  bool _isProcessing = false;

  static const List<int> _presetAmounts = [1000, 2500, 5000, 10000, 20000, 50000];

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialOpenFund ? _WalletViewMode.fund : _WalletViewMode.overview;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectPreset(int amount) {
    setState(() {
      _selectedPresetAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  Future<void> _processFunding(RidesViewModel vm) async {
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount < 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum funding amount is ₦200'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final methodLabel = _selectedFundingMethod == 'card'
        ? 'Debit Card'
        : (_selectedFundingMethod == 'bank' ? 'Bank Transfer' : 'USSD');

    final success = await vm.fundWallet(amount, methodLabel);

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      if (success) {
        _viewMode = _WalletViewMode.overview;
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('₦${NumberFormat('#,###').format(amount)} added successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RidesViewModel>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF0F121A),
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
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (_viewMode != _WalletViewMode.overview) ...[
                  IconButton(
                    onPressed: () => setState(() => _viewMode = _WalletViewMode.overview),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0x26F5A623),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x4DF5A623)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFF5A623), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _viewMode == _WalletViewMode.overview
                        ? 'DOGO Wallet'
                        : (_viewMode == _WalletViewMode.fund ? 'Top up wallet' : 'Bank Transfer Details'),
                    style: GoogleFonts.sora(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0x1AFFFFFF), height: 1),

          // Content Area
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _buildBody(context, vm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, RidesViewModel vm) {
    switch (_viewMode) {
      case _WalletViewMode.overview:
        return _buildOverview(context, vm);
      case _WalletViewMode.fund:
        return _buildFundView(context, vm);
      case _WalletViewMode.bankDetails:
        return _buildBankDetailsView(context);
    }
  }

  // 1. Overview Screen
  Widget _buildOverview(BuildContext context, RidesViewModel vm) {
    final transactions = vm.walletTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Balance Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E2638), Color(0xFF141824)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x4DF5A623), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5A623).withAlpha(30),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 6),
                      Text(
                        'AVAILABLE BALANCE',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9CA3AF),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
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
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  vm.formattedWalletBalance,
                  style: GoogleFonts.sora(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF5A623),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons: "+ Top up" & "Bank transfer"
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _viewMode = _WalletViewMode.fund),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'Top up wallet',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _viewMode = _WalletViewMode.bankDetails),
                      icon: const Icon(Icons.account_balance_rounded, size: 16),
                      label: Text(
                        'Bank transfer',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x2EFFFFFF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Recent Activity Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent activity',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2230),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${transactions.length} transactions',
                style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Transactions List
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF141722),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            alignment: Alignment.center,
            child: Text(
              'No wallet transactions yet.',
              style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF)),
            ),
          )
        else
          ...transactions.map((tx) => _buildTransactionTile(context, tx)),
      ],
    );
  }

  Widget _buildTransactionTile(BuildContext context, WalletTransactionModel tx) {
    final isCredit = tx.isCredit;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          // Icon Pill
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit ? const Color(0x2610B981) : const Color(0x262563EB),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : (tx.type == WalletTransactionType.courier
                      ? Icons.inventory_2_outlined
                      : Icons.directions_car_rounded),
              color: isCredit ? const Color(0xFF10B981) : const Color(0xFF60A5FA),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.method} • ${tx.formattedDate}',
                  style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Amount
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tx.formattedAmount,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isCredit ? const Color(0xFF10B981) : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Fund Wallet View
  Widget _buildFundView(BuildContext context, RidesViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select or enter amount',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Custom Amount Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
          ),
          child: Row(
            children: [
              Text(
                '₦',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF5A623),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: Color(0xFF6B7280)),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) {
                    final parsed = int.tryParse(val) ?? 0;
                    setState(() => _selectedPresetAmount = parsed);
                  },
                ),
              ),
              if (_amountController.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _amountController.clear();
                    setState(() => _selectedPresetAmount = 0);
                  },
                  icon: const Icon(Icons.cancel_rounded, color: Color(0xFF6B7280), size: 18),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Preset Amount Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetAmounts.map((amt) {
            final isSelected = _selectedPresetAmount == amt;
            return ChoiceChip(
              label: Text('₦${NumberFormat('#,###').format(amt)}'),
              selected: isSelected,
              onSelected: (_) => _selectPreset(amt),
              backgroundColor: const Color(0xFF141722),
              selectedColor: const Color(0xFF2563EB).withAlpha(50),
              labelStyle: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF93C5FD) : Colors.white,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Payment Method Header
        Text(
          'Choose payment method',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        // 1. Debit Card
        _buildPaymentOption(
          id: 'card',
          icon: Icons.credit_card_rounded,
          title: 'Debit Card (Instant)',
          subtitle: 'Visa, Mastercard, Verve',
        ),

        const SizedBox(height: 8),

        // 2. Direct Bank Transfer
        _buildPaymentOption(
          id: 'bank',
          icon: Icons.account_balance_rounded,
          title: 'Direct Bank Transfer',
          subtitle: 'Automated instant virtual account',
        ),

        const SizedBox(height: 8),

        // 3. USSD
        _buildPaymentOption(
          id: 'ussd',
          icon: Icons.dialpad_rounded,
          title: 'USSD Transfer',
          subtitle: '*737#, *894#, *966# and more',
        ),

        const SizedBox(height: 26),

        // Pay Button
        ElevatedButton(
          onPressed: _isProcessing ? null : () => _processFunding(vm),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Fund ${_amountController.text.isNotEmpty ? '₦${NumberFormat('#,###').format(int.tryParse(_amountController.text) ?? 0)}' : 'Wallet'}',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedFundingMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedFundingMethod = id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141722),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0x1FFFFFFF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB).withAlpha(40) : const Color(0xFF1B1F2C),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFF9CA3AF), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // 3. Bank Details View
  Widget _buildBankDetailsView(BuildContext context) {
    const accountNumber = '9023418291';
    const bankName = 'Wema Bank / DOGO MFB';
    const accountName = 'DOGO Rides — Amaka Nwosu';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x33F5A623)),
          ),
          child: Column(
            children: [
              const Icon(Icons.account_balance_rounded, size: 40, color: Color(0xFFF5A623)),
              const SizedBox(height: 12),
              Text(
                'Personal Virtual Account',
                style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Transfers to this account fund your DOGO wallet instantly 24/7.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0x1FFFFFFF), height: 1),
              const SizedBox(height: 14),

              // Account Number Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account number', style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF))),
                      const SizedBox(height: 2),
                      Text(
                        accountNumber,
                        style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: accountNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account number copied to clipboard!'),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF93C5FD),
                      side: const BorderSide(color: Color(0x4D2563EB)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: Color(0x1FFFFFFF), height: 1),
              const SizedBox(height: 14),

              _buildDetailRow('Bank name', bankName),
              const SizedBox(height: 10),
              _buildDetailRow('Beneficiary', accountName),
            ],
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: () => setState(() => _viewMode = _WalletViewMode.fund),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Top up with Card instead'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF))),
        Text(value, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}
