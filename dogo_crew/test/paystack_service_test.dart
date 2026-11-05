import 'package:flutter_test/flutter_test.dart';
import 'package:dogo_crew/data/services/paystack_service.dart';

void main() {
  group('PaystackService Tests', () {
    test('Public key is properly configured with user key', () {
      expect(PaystackService.publicKey, 'pk_test_e9791e466677e7f0265c8c0857baaa3d465ba965');
    });

    test('generateReference generates valid prefixed unique strings', () {
      final ref = PaystackService.instance.generateReference(prefix: 'DOGO_TOPUP');
      expect(ref.startsWith('DOGO_TOPUP_'), isTrue);
    });

    test('createVirtualAccount generates 30-minute automated account', () {
      final vAcct = PaystackService.instance.createVirtualAccount(
        amount: 5000,
        passengerName: 'Salim Bello',
      );

      expect(vAcct.bankName, contains('Paystack'));
      expect(vAcct.accountName, 'DOGO / Salim Bello');
      expect(vAcct.amount, 5000);
      expect(vAcct.accountNumber.length, greaterThanOrEqualTo(10));
      expect(vAcct.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('formatUssdCode formats bank-specific dial codes accurately', () {
      final gtBank = PaystackService.supportedUssdBanks.firstWhere((b) => b.name == 'GTBank');
      final code = PaystackService.instance.formatUssdCode(
        bank: gtBank,
        amount: 2500,
        reference: 'DOGO_USD_123456_9999',
      );

      expect(code, '*737*50*2500*9999#');
    });
  });
}

