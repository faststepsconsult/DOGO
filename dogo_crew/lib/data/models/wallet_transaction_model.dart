import 'package:intl/intl.dart';

enum WalletTransactionType { topup, ride, courier, refund }

class WalletTransactionModel {
  final String id;
  final String title;
  final int amount;
  final bool isCredit;
  final DateTime timestamp;
  final String method;
  final String? tripCode;
  final String status;
  final WalletTransactionType type;

  const WalletTransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.isCredit,
    required this.timestamp,
    required this.method,
    this.tripCode,
    this.status = 'completed',
    this.type = WalletTransactionType.topup,
  });

  String get formattedAmount {
    final prefix = isCredit ? '+₦' : '-₦';
    return '$prefix${NumberFormat('#,###').format(amount)}';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(timestamp)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
