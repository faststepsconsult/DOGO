import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/wallet_transaction_model.dart';
import '../../../../data/services/audio_cues_service.dart';
import '../../../../data/services/paystack_service.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/rides_view_model.dart';

enum _WalletViewMode {
  overview,
  fund,
  bankDetails,
  paystackCard,
  paystackBankTransfer,
  paystackUssd,
  successReceipt,
}

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

  // Paystack Active Session State
  String? _activePaystackReference;
  String? _activePaystackAuthUrl;
  PaystackVirtualAccount? _activeVirtualAccount;
  PaystackBankInfo _selectedUssdBank = PaystackService.supportedUssdBanks[0];
  String? _lastFundedMethod;
  int? _lastFundedAmount;

  // Countdown timer for virtual account transfer
  Timer? _countdownTimer;
  int _countdownSeconds = 1800; // 30 minutes

  static const List<int> _presetAmounts = [1000, 2500, 5000, 10000, 20000, 50000];

  @override
  void initState() {
    super.initState();
    _viewMode = widget.initialOpenFund ? _WalletViewMode.fund : _WalletViewMode.overview;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _selectPreset(int amount) {
    setState(() {
      _selectedPresetAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownSeconds = 1800;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        if (mounted) setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ==========================================
  // Paystack Action Dispatchers
  // ==========================================

  Future<void> _handleProceedToPaystack(RidesViewModel vm, AuthViewModel authVm) async {
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

    final passengerName = authVm.displayName.isNotEmpty ? authVm.displayName : 'Salim Bello';
    final passengerEmail = authVm.currentUser?.email ?? 'salim@dogo.ng';

    if (_selectedFundingMethod == 'card') {
      // 1. Debit Card Gateway
      setState(() => _isProcessing = true);
      final ref = PaystackService.instance.generateReference(prefix: 'DOGO_CRD');
      final initResult = await PaystackService.instance.initializeTransaction(
        amountInNaira: amount,
        email: passengerEmail,
        reference: ref,
        channels: ['card'],
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _activePaystackReference = ref;
        _activePaystackAuthUrl = initResult.authorizationUrl;
        _viewMode = _WalletViewMode.paystackCard;
      });

      // Automatically launch checkout URL in in-app browser view
      if (initResult.authorizationUrl != null) {
        await PaystackService.instance.launchCheckoutUrl(initResult.authorizationUrl!);
      }
    } else if (_selectedFundingMethod == 'bank') {
      // 2. Direct Bank Transfer (Virtual Account)
      final ref = PaystackService.instance.generateReference(prefix: 'DOGO_BNK');
      final vAcct = PaystackService.instance.createVirtualAccount(
        amount: amount,
        passengerName: passengerName,
        reference: ref,
      );
      setState(() {
        _activePaystackReference = ref;
        _activeVirtualAccount = vAcct;
        _viewMode = _WalletViewMode.paystackBankTransfer;
      });
      _startCountdownTimer();
    } else if (_selectedFundingMethod == 'ussd') {
      // 3. USSD Dialing Gateway
      final ref = PaystackService.instance.generateReference(prefix: 'DOGO_USD');
      setState(() {
        _activePaystackReference = ref;
        _viewMode = _WalletViewMode.paystackUssd;
      });
    }
  }

  /// Verifies transaction and credits wallet
  Future<void> _verifyAndCreditWallet(RidesViewModel vm, {required String methodLabel}) async {
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final ref = _activePaystackReference ?? PaystackService.instance.generateReference();

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1400));

    final verifyResult = await PaystackService.instance.verifyTransaction(ref);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (verifyResult.success) {
      final success = await vm.fundWallet(amount, 'Paystack: $methodLabel');
      if (success) {
        AudioCuesService.instance.playTipReceived();
        try {
          HapticFeedback.heavyImpact();
        } catch (_) {}

        setState(() {
          _lastFundedMethod = methodLabel;
          _lastFundedAmount = amount;
          _viewMode = _WalletViewMode.successReceipt;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RidesViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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
                if (_viewMode != _WalletViewMode.overview && _viewMode != _WalletViewMode.successReceipt) ...[
                  IconButton(
                    onPressed: () {
                      if (_viewMode == _WalletViewMode.paystackCard ||
                          _viewMode == _WalletViewMode.paystackBankTransfer ||
                          _viewMode == _WalletViewMode.paystackUssd) {
                        setState(() => _viewMode = _WalletViewMode.fund);
                      } else {
                        setState(() => _viewMode = _WalletViewMode.overview);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0x2600C3F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x4D00C3F7)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF00C3F7), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getHeaderTitle(),
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
              child: _buildBody(context, vm, authVm),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_viewMode) {
      case _WalletViewMode.overview:
        return 'DOGO Wallet';
      case _WalletViewMode.fund:
        return 'Paystack Top-up';
      case _WalletViewMode.bankDetails:
        return 'Personal Account';
      case _WalletViewMode.paystackCard:
        return 'Card Checkout';
      case _WalletViewMode.paystackBankTransfer:
        return 'Pay with Transfer';
      case _WalletViewMode.paystackUssd:
        return 'Pay with USSD';
      case _WalletViewMode.successReceipt:
        return 'Top-up Successful';
    }
  }

  Widget _buildBody(BuildContext context, RidesViewModel vm, AuthViewModel authVm) {
    switch (_viewMode) {
      case _WalletViewMode.overview:
        return _buildOverview(context, vm);
      case _WalletViewMode.fund:
        return _buildFundView(context, vm, authVm);
      case _WalletViewMode.bankDetails:
        return _buildBankDetailsView(context);
      case _WalletViewMode.paystackCard:
        return _buildPaystackCardView(context, vm);
      case _WalletViewMode.paystackBankTransfer:
        return _buildPaystackBankTransferView(context, vm);
      case _WalletViewMode.paystackUssd:
        return _buildPaystackUssdView(context, vm);
      case _WalletViewMode.successReceipt:
        return _buildSuccessReceiptView(context, vm);
    }
  }

  // ==========================================
  // 1. OVERVIEW SCREEN
  // ==========================================

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
                      color: const Color(0x1A10B981),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x3310B981)),
                    ),
                    child: Text(
                      'Paystack Secured',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                vm.formattedWalletBalance,
                style: GoogleFonts.sora(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _viewMode = _WalletViewMode.fund),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
                      label: Text(
                        'Top up Wallet',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _viewMode = _WalletViewMode.bankDetails),
                      icon: const Icon(Icons.account_balance_outlined, size: 17),
                      label: Text(
                        'Bank Details',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x33FFFFFF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Transactions Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent activity',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '${transactions.length} items',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF141722),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'No transactions recorded yet',
                style: GoogleFonts.manrope(color: const Color(0xFF9CA3AF)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) => _buildTransactionItem(transactions[idx]),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(WalletTransactionModel tx) {
    final isCredit = tx.isCredit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
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
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
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

  // ==========================================
  // 2. FUND VIEW (PAYSTACK GATEWAY SELECTOR)
  // ==========================================

  Widget _buildFundView(BuildContext context, RidesViewModel vm, AuthViewModel authVm) {
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select or enter amount',
              style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x1A00C3F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 11, color: Color(0xFF00C3F7)),
                  const SizedBox(width: 4),
                  Text(
                    'Paystack Official',
                    style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF00C3F7)),
                  ),
                ],
              ),
            ),
          ],
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

        // Paystack Payment Gateways
        Text(
          'Select Paystack Gateway',
          style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        // 1. Debit Card
        _buildPaymentOption(
          id: 'card',
          icon: Icons.credit_card_rounded,
          title: 'Debit Card (Paystack Standard)',
          subtitle: 'Visa • Mastercard • Verve (Instant)',
          badgeText: 'Instant',
        ),

        const SizedBox(height: 8),

        // 2. Direct Bank Transfer
        _buildPaymentOption(
          id: 'bank',
          icon: Icons.account_balance_rounded,
          title: 'Direct Bank Transfer',
          subtitle: 'Dedicated automated Wema / Titan account',
          badgeText: 'Auto-Credit',
        ),

        const SizedBox(height: 8),

        // 3. USSD
        _buildPaymentOption(
          id: 'ussd',
          icon: Icons.dialpad_rounded,
          title: 'USSD Dialing Gateway',
          subtitle: 'GTBank (*737*), Zenith (*966*), Access (*901*) & more',
          badgeText: 'Offline-Ready',
        ),

        const SizedBox(height: 26),

        // Pay Button
        ElevatedButton(
          onPressed: _isProcessing ? null : () => _handleProceedToPaystack(vm, authVm),
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
                      'Pay ₦${NumberFormat('#,###').format(amount)} with Paystack',
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
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
    String? badgeText,
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
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x1A10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.manrope(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ],
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

  // ==========================================
  // 3. PAYSTACK CARD CHECKOUT VIEW
  // ==========================================

  Widget _buildPaystackCardView(BuildContext context, RidesViewModel vm) {
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final formattedAmount = '₦${NumberFormat('#,###').format(amount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x332563EB), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0x262563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.credit_card_rounded, color: Color(0xFF60A5FA), size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'Paystack Card Checkout',
                style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete your payment of $formattedAmount in the secure Paystack checkout.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF), height: 1.4),
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0x1FFFFFFF), height: 1),
              const SizedBox(height: 14),
              _buildDetailRow('Amount', formattedAmount),
              const SizedBox(height: 8),
              _buildDetailRow('Reference', _activePaystackReference ?? '—'),
              const SizedBox(height: 8),
              _buildDetailRow('Gateway Status', 'Awaiting Confirmation'),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Re-launch Checkout Button
        if (_activePaystackAuthUrl != null)
          OutlinedButton.icon(
            onPressed: () => PaystackService.instance.launchCheckoutUrl(_activePaystackAuthUrl!),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(
              'Re-open Paystack Checkout',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF60A5FA),
              side: const BorderSide(color: Color(0x4D2563EB)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

        const SizedBox(height: 10),

        // Verify Payment Button
        ElevatedButton(
          onPressed: _isProcessing ? null : () => _verifyAndCreditWallet(vm, methodLabel: 'Debit Card'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'I Have Completed Payment',
                  style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. PAYSTACK BANK TRANSFER (VIRTUAL ACCOUNT)
  // ==========================================

  Widget _buildPaystackBankTransferView(BuildContext context, RidesViewModel vm) {
    final vAcct = _activeVirtualAccount;
    if (vAcct == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final formattedAmount = '₦${NumberFormat('#,###').format(vAcct.amount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Virtual Account Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x3300C3F7), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1A00C3F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Paystack Titan Virtual Account',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00C3F7),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFF5A623)),
                      const SizedBox(width: 4),
                      Text(
                        _formatCountdown(_countdownSeconds),
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF5A623),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Transfer Exactly $formattedAmount',
                style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Send funds to the dedicated account below via your banking app or USSD.',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF9CA3AF), height: 1.4),
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0x1FFFFFFF), height: 1),
              const SizedBox(height: 14),

              // Account Number Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0C12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACCOUNT NUMBER',
                            style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          vAcct.accountNumber,
                          style: GoogleFonts.sora(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vAcct.accountNumber));
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              _buildDetailRow('Bank Name', vAcct.bankName),
              const SizedBox(height: 8),
              _buildDetailRow('Beneficiary', vAcct.accountName),
              const SizedBox(height: 8),
              _buildDetailRow('Amount', formattedAmount),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Confirm Button
        ElevatedButton(
          onPressed: _isProcessing ? null : () => _verifyAndCreditWallet(vm, methodLabel: 'Bank Transfer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'I Have Sent the Money',
                  style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. PAYSTACK USSD GATEWAY VIEW
  // ==========================================

  Widget _buildPaystackUssdView(BuildContext context, RidesViewModel vm) {
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final ref = _activePaystackReference ?? 'DOGO_9481';
    final ussdString = PaystackService.instance.formatUssdCode(
      bank: _selectedUssdBank,
      amount: amount,
      reference: ref,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF141722),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x33F5A623), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Your Bank',
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x1AF5A623),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Instant USSD',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5A623),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bank Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F121B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PaystackBankInfo>(
                    value: _selectedUssdBank,
                    dropdownColor: const Color(0xFF141722),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                    isExpanded: true,
                    items: PaystackService.supportedUssdBanks.map((b) {
                      return DropdownMenuItem(
                        value: b,
                        child: Text(
                          b.name,
                          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUssdBank = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 18),
              const Divider(color: Color(0x1FFFFFFF), height: 1),
              const SizedBox(height: 14),

              Text('USSD DIALING CODE',
                  style: GoogleFonts.manrope(fontSize: 10, color: const Color(0xFF9CA3AF), fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),

              // Code Dial Display Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0C12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x33F5A623)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ussdString,
                        style: GoogleFonts.sora(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF5A623),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: ussdString));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('USSD code copied!'),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
                      tooltip: 'Copy Code',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Dial USSD Now" to open phone dialer automatically.',
                style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Dial Button (Calls url_launcher with tel:)
        ElevatedButton.icon(
          onPressed: () => PaystackService.instance.dialUssd(ussdString),
          icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
          label: Text(
            'Dial USSD Now',
            style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 10),

        // Confirm Transfer Done
        OutlinedButton(
          onPressed: _isProcessing ? null : () => _verifyAndCreditWallet(vm, methodLabel: 'USSD (${_selectedUssdBank.name})'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF10B981),
            side: const BorderSide(color: Color(0x6610B981), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2),
                )
              : Text(
                  'I Have Completed the USSD Payment',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. SUCCESS RECEIPT VIEW
  // ==========================================

  Widget _buildSuccessReceiptView(BuildContext context, RidesViewModel vm) {
    final amount = _lastFundedAmount ?? 5000;
    final method = _lastFundedMethod ?? 'Paystack Gateway';
    final formattedAmount = '₦${NumberFormat('#,###').format(amount)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF0F121A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x6610B981), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0x3310B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                'Wallet Funded!',
                style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '$formattedAmount added to your DOGO wallet',
                style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFFD1D5DB)),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0x1FFFFFFF), height: 1),
              const SizedBox(height: 14),
              _buildDetailRow('Amount Paid', formattedAmount),
              const SizedBox(height: 8),
              _buildDetailRow('Payment Channel', method),
              const SizedBox(height: 8),
              _buildDetailRow('Status', 'Successful & Verified'),
              const SizedBox(height: 8),
              _buildDetailRow('New Wallet Balance', vm.formattedWalletBalance),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => setState(() => _viewMode = _WalletViewMode.overview),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Return to Wallet',
            style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 7. PERSISTENT PERSONAL VIRTUAL ACCOUNT
  // ==========================================

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
          child: const Text('Top up with Paystack instead'),
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
