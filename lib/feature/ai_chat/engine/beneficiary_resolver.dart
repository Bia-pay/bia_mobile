
class UnifiedContact {
  final String name;
  final String account;
  final String bankCode; // Empty string if internal

  UnifiedContact({
    required this.name,
    required this.account,
    this.bankCode = '',
  });

  bool get isBankTransfer => bankCode.isNotEmpty;
}

/// Fuzzy-matches a user-typed name/phone against the beneficiary list.
/// Returns matches ranked by relevance (exact first, then partial).
class BeneficiaryResolver {
  List<UnifiedContact> resolve(
    String query,
    List<UnifiedContact> all,
  ) {
    if (query.isEmpty || all.isEmpty) return [];

    final q = query.toLowerCase().trim();

    // Exact phone / account number match
    final phoneMatch = all.where((b) => b.account.toLowerCase() == q).toList();
    if (phoneMatch.isNotEmpty) return phoneMatch;

    // Split query into tokens for partial name matching
    final tokens = q.split(RegExp(r'\s+'));

    final scored = <({UnifiedContact item, int score})>[];

    for (final b in all) {
      final name = b.name.toLowerCase();
      int score = 0;

      // Exact full-name match
      if (name == q) {
        score = 100;
      } else {
        for (final token in tokens) {
          if (token.length < 2) continue;
          if (name.contains(token)) score += 30;
          if (name.startsWith(token)) score += 20;
        }
        if (name.startsWith(q)) score += 10;
      }

      if (score > 0) scored.add((item: b, score: score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.item).toList();
  }
}
