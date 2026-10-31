class WalletModel {
  final int balance;
  final int today;
  final int tripsDone;

  WalletModel({
    required this.balance,
    required this.today,
    required this.tripsDone,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      today: (json['today'] as num?)?.toInt() ?? 0,
      tripsDone: (json['trips_done'] as num?)?.toInt() ?? 0,
    );
  }
}
