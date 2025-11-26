import 'package:intl/intl.dart';

import '../../feature/auth/modal/reponse/response_modal.dart';

String formatTransactionDate(String? rawDate) {
  if (rawDate == null || rawDate.isEmpty) return '';

  try {
    final dt = DateTime.parse(rawDate);
    final now = DateTime.now();

    // If today, show only time
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat.jm().format(dt); // just time for today
    }

    // If this year, show month + day + time
    if (dt.year == now.year) {
      return DateFormat('MMM d || h:mm a').format(dt); // e.g., Nov 24 || 3:45 PM
    }

    // Otherwise, show full date
    return DateFormat('yMMMd || h:mm a').format(dt); // e.g., Nov 24, 2025 || 3:45 PM
  } catch (e) {
    return rawDate; // fallback
  }
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