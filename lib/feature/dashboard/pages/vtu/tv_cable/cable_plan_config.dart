class CablePlanConfig {
  /// 🔹 IMAGE MAP
  static String getPlanImage(Map<String, dynamic> plan) {
    final code = plan['variation_code']?.toString().toLowerCase() ?? '';
    final name = plan['name']?.toString().toLowerCase() ?? '';

    /// DSTV
    if (code.contains('padi') || name.contains('padi')) {
      return 'assets/images/padi.jpg';
    }
    if (code.contains('yanga') || name.contains('yanga')) {
      return 'assets/images/yanga.jpg';
    }
    if (code.contains('confam') || name.contains('confam')) {
      return 'assets/images/confam.jpg';
    }
    if ((code.contains('compact') && (code.contains('plus') || code.contains('+'))) ||
        (name.contains('compact') && (name.contains('plus') || name.contains('+')))) {
      return (code.hashCode % 2 == 0)
          ? 'assets/images/compact_plus.png'
          : 'assets/images/compact_plus.jpeg';
    }
    if (code.contains('compact') || name.contains('compact')) {
      return (code.hashCode % 2 == 0)
          ? 'assets/images/compact.png'
          : 'assets/images/compacct.jpeg';
    }
    if (code.contains('asia') || name.contains('asia')) {
      return 'assets/images/asia.png';
    }
    if (code.contains('premium') || name.contains('premium')) {
      return 'assets/images/premium.jpeg';
    }

    /// GOTV (Mapped safely to the exact gotv assets)
    if ((code.contains('supa') && (code.contains('plus') || code.contains('+') || code.contains('pls'))) ||
        (name.contains('supa') && (name.contains('plus') || name.contains('+') || name.contains('pls')))) {
      return 'assets/images/gotv_supa_pls.jpg';
    }
    if (code.contains('supa') || name.contains('supa')) {
      return 'assets/images/gotv_supa.jpeg';
    }
    if (code.contains('jolli') || name.contains('jolli')) {
      return 'assets/images/gotv_jolli.jpg';
    }
    if (code.contains('jinja') || name.contains('jinja')) {
      return 'assets/images/gotv_jinja.jpg';
    }
    if (code.contains('max') || name.contains('max')) {
      return 'assets/images/gotv_max.jpeg';
    }
    if (code.contains('smallie') || name.contains('smallie') || code.contains('lite') || name.contains('lite')) {
      return 'assets/images/gotv_smallie.jpg';
    }

    /// STARTIMES (Mapped safely to the newly added local startimes assets)
    if (code.contains('nova') || name.contains('nova')) {
      return 'assets/images/startimes_nova.jpg';
    }
    if (code.contains('basic') || name.contains('basic')) {
      return 'assets/images/startimes_basic.webp';
    }
    if (code.contains('classic') || name.contains('classic')) {
      return 'assets/images/startimes_classic.webp';
    }
    if (code.contains('smart') || name.contains('smart')) {
      return 'assets/images/sta.jpg';
    }
    if (code.contains('super') || name.contains('super')) {
      return 'assets/images/startimes_super.jpeg';
    }
    if (code.contains('SHS') || name.contains('super')) {
      return 'assets/images/startimes_super.jpeg';
    }

    /// SHOWMAX
    if (code.contains('showmax') || name.contains('showmax')) {
      return 'assets/images/asia.png';
    }

    /// DEFAULT FALLBACK (Deterministic choose from verified existing local assets)
    final fallbacks = [
      'assets/images/padi.jpg',
      'assets/images/yanga.jpg',
      'assets/images/confam.jpg',
      'assets/images/compact.png',
      'assets/images/premium.jpeg',
    ];
    return fallbacks[code.hashCode % fallbacks.length];
  }

  /// 🔹 DESCRIPTION MAP
  static String getPlanDescription(String? code) {
    final c = code?.toLowerCase() ?? '';

    final descriptions = {
      /// DSTV
      'dstv-padi': '45+ channels with Nollywood and local content.',
      'dstv-yanga': '85+ channels including movies and sports.',
      'dstv-confam': '105+ channels for full family entertainment.',
      'dstv79': 'DStv Compact package.',
      'dstv3': 'Premium package with 175+ channels.',

      /// GOTV
      'gotv-jolli': 'Family entertainment bundle.',
      'gotv-jinja': 'Affordable everyday TV.',
      'gotv-max': 'Full entertainment experience.',
      'gotv-lite': 'Budget-friendly TV.',
      'gotv-supa-plus': 'Top GOtv experience.',

      /// STARTIMES
      'nova': 'Entry level entertainment.',
      'basic': 'Basic entertainment channels.',
      'smart': 'More variety and content.',
      'classic': 'Premium movies and sports.',
      'super': 'Full premium package.',
      'shs': 'Full premium package.',

      /// SHOWMAX
      'showmax': 'Stream movies and series anytime.',
    };

    return descriptions[c] ??
        'Enjoy premium entertainment tailored for you.';
  }
}