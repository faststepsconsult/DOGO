import 'package:intl/intl.dart';

enum WalletTransactionType { topup, ride, courier, refund, tip, payout }

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'is_credit': isCredit,
      'timestamp': timestamp.toIso8601String(),
      'method': method,
      'trip_code': tripCode,
      'status': status,
      'type': type.name,
    };
  }

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String? ?? 'TX-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Transaction',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      isCredit: json['is_credit'] as bool? ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      method: json['method'] as String? ?? 'DOGO Wallet',
      tripCode: json['trip_code'] as String?,
      status: json['status'] as String? ?? 'completed',
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WalletTransactionType.topup,
      ),
    );
  }
}
