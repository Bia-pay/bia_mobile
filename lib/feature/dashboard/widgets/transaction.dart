// First, define your transaction model
class Transaction {
  final String name;
  final String dateTime;
  final double amount;
  final bool isOutgoing;

  Transaction({
    required this.name,
    required this.dateTime,
    required this.amount,
    this.isOutgoing = true,
  });
}

// Example dummy transactions list
final List<Transaction> transactions = [
  Transaction(name: "Musa Ali", dateTime: "Sep 09  12:19pm", amount: 250, isOutgoing: true),
  Transaction(name: "Salma Gambo", dateTime: "Sep 10  9:45am", amount: 1200, isOutgoing: false),
  Transaction(name: "John Doe", dateTime: "Sep 11  3:15pm", amount: 500, isOutgoing: true),
  Transaction(name: "Aisha Bello", dateTime: "Sep 10  9:45am", amount: 1200, isOutgoing: false),
];// First, define your transaction model
class TopUp {
  final String name;
  final String dateTime;
  final double amount;
  final bool isOutgoing;

  TopUp({
    required this.name,
    required this.dateTime,
    required this.amount,
    this.isOutgoing = true,
  });
}

// Example dummy transactions list
final List<TopUp> topUp = [
  TopUp(name: "Cash Deposit", dateTime: "Fund your account with nearby agents", amount: 250, isOutgoing: true),
  TopUp(name: "Top-up with Card/Account", dateTime: "Add money from your bank card/account", amount: 1200, isOutgoing: false),
  TopUp(name: "USSD", dateTime: "Use your other bank's USSD code", amount: 500, isOutgoing: true),
  TopUp(name: "Receive Money", dateTime: "Share your account and ask for transfer", amount: 1200, isOutgoing: false),
];
class DataTopUp {
  final String name;
  final String dateTime;
  final double amount;
  final bool isOutgoing;

  DataTopUp({
    required this.name,
    required this.dateTime,
    required this.amount,
    this.isOutgoing = true,
  });
}

final List<TopUp> dataPlans = [
  TopUp(name: "Schedule Top-up", dateTime: "Never run out of data", amount: 250, isOutgoing: true),
  TopUp(name: "Airtime Group Purchase", dateTime: "Team up & Enjoy 50% OFF!", amount: 1200, isOutgoing: false),
];