/// Structural and static UI strings for the BIA AI experience.
class BiaStrings {
  const BiaStrings._();

  // ── Static Greeting fallback ──────────────────────────────────────────────
  static String welcome(String lang) {
    switch (lang) {
      case 'hausa':
        return 'Sannu! 👋 Ni ne Bia AI. Yaya zan iya taimaka maka yau?';
      case 'pidgin':
        return 'How far! 👋 I be Bia AI. Wetin I fit do for you today?';
      default:
        return 'Hello! 👋 I am Bia AI. How can I help you today?';
    }
  }

  // ── Labels for Confirm Card (Keeping these for UI consistency) ─────────────
  static String transferToBankLabel(String lang, String bankName) {
    switch (lang) {
      case 'hausa':
        return 'Canja zuwa $bankName';
      case 'pidgin':
        return 'Send to $bankName';
      default:
        return 'Transfer to $bankName';
    }
  }
}
