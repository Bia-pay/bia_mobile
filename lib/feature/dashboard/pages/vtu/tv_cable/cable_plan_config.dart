class CablePlanConfig {
  /// 🔹 IMAGE MAP
  static String getPlanImage(Map<String, dynamic> plan) {
    final code = plan['variation_code']?.toString().toLowerCase() ?? '';

    /// DSTV
    if (code.contains('padi')) return 'assets/images/padi.jpg';
    if (code.contains('yanga')) return 'assets/images/yanga.jpg';
    if (code.contains('confam')) return 'assets/images/confam.jpg';
    if (code.contains('compact') && code.contains('plus')) return 'assets/images/compact_plus.png';
    if (code.contains('compact')) return 'assets/images/compact.png';
    if (code.contains('premium')) return 'assets/images/premium.jpg';

    /// ADD MORE PROVIDERS BELOW 👇

    /// GOTV
    if (code.contains('jolli')) return 'assets/images/gotv/jolli.jpg';
    if (code.contains('jinja')) return 'assets/images/gotv/jinja.jpg';
    if (code.contains('max')) return 'assets/images/gotv/max.jpg';
    if (code.contains('lite')) return 'assets/images/gotv/lite.jpg';
    if (code.contains('supa')) return 'assets/images/gotv/supa.jpg';

    /// STARTIMES
    if (code.contains('nova')) return 'assets/images/startimes/nova.jpg';
    if (code.contains('basic')) return 'assets/images/startimes/basic.jpg';
    if (code.contains('smart')) return 'assets/images/startimes/smart.jpg';
    if (code.contains('classic')) return 'assets/images/startimes/classic.jpg';
    if (code.contains('super')) return 'assets/images/startimes/super.jpg';

    /// SHOWMAX
    if (code.contains('showmax')) return 'assets/images/showmax/showmax.jpg';

    /// DEFAULT
    return 'assets/images/default.png';
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

      /// SHOWMAX
      'showmax': 'Stream movies and series anytime.',
    };

    return descriptions[c] ??
        'Enjoy premium entertainment tailored for you.';
  }
}