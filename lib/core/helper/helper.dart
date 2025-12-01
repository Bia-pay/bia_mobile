import 'package:intl/intl.dart';

import '../../feature/auth/modal/reponse/response_modal.dart';
String formatTransactionDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('dd MMM yyyy, hh:mm a').format(date);
}
class WalletResponse extends ResponseBody {
  final String balance;
  final String currency;
  final Map<String, dynamic> limits;

  WalletResponse({
    required this.balance,
    required this.currency,
    required this.limits,
  });
}