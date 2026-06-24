import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Provider for the app-wide locale (Language).
final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, Locale>((ref) {
  return AppLocaleNotifier();
});

class AppLocaleNotifier extends StateNotifier<Locale> {
  AppLocaleNotifier() : super(const Locale('en')) {
    _loadStoredLocale();
  }

  static const String _boxName = 'appPrefs';
  static const String _key = 'appLocaleCode';

  Future<void> _loadStoredLocale() async {
    final box = await Hive.openBox(_boxName);
    final code = box.get(_key, defaultValue: 'en');
    state = Locale(code);
  }

  Future<void> setLocale(String languageCode) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_key, languageCode);
    state = Locale(languageCode);
  }

  /// Returns the human-readable name of the current language.
  String get currentLanguageName {
    switch (state.languageCode) {
      case 'en': return 'English';
      case 'ha': return 'Hausa';
      case 'pcm': return 'Pidgin';
      default: return 'English';
    }
  }

  /// Simple translation bridge for core UI strings
  String translate(String key) {
    final Map<String, Map<String, String>> localizedStrings = {
      'en': {
        'hub_settings': 'Settings',
        'hub_desc': 'Manage your account security and preferences',
        'security_login': 'Security & Login',
        'prefs_support': 'Preferences & Support',
        'language': 'Language',
        'help': 'Help',
        'log_out': 'Log Out',
        'generate_qr': 'Generate QR Code',
        'verified_account': 'Verified Account',
        'pin_settings': 'Pin Settings',
        'login_settings': 'Login Settings',
        'payment_settings': 'Payment Settings',
        'set_pin': 'Set Pin',
        'change_payment_pin': 'Change Payment Pin',
        'forget_payment_pin': 'Forget Payment Pin',
        'pay_with': 'Pay with',
        'change_password': 'Change Password',
        'forget_password': 'Forget Password',
        'auto_logout_settings': 'Auto Logout Settings',
        'login_with': 'Login with',
        'help_center': 'Help Center',
        'enable_scan_to_receive': 'Enable Scan to Receive',
        'refer_and_earn': 'Refer & Earn',
      },
      'ha': {
        'hub_settings': 'Saitunan Hub',
        'hub_desc': 'Sarrafa tsaro da abubuwan da kuke so na asusunku',
        'security_login': 'Tsaro da Shiga',
        'prefs_support': 'Gaba da Taimako',
        'language': 'Yare',
        'help': 'Taimako',
        'log_out': 'Fita',
        'generate_qr': 'Sanya Lambar QR',
        'verified_account': 'Ingantaccen Asusu',
        'pin_settings': 'Saitunan Pin',
        'login_settings': 'Saitunan Shiga',
        'payment_settings': 'Saitunan Biyan Kudi',
        'set_pin': 'Sanya Pin',
        'change_payment_pin': 'Canza Pin din Biyan Kudi',
        'forget_payment_pin': 'Manta Pin din Biyan Kudi',
        'pay_with': 'Biya da',
        'change_password': 'Canza Kalmar Sirri',
        'forget_password': 'Manta Kalmar Sirri',
        'auto_logout_settings': 'Sanya Mafitar Kai tsaye',
        'login_with': 'Shiga da',
        'help_center': 'Cibiyar Taimako',
        'enable_scan_to_receive': 'Kunna Dubawa don Karba',
        'refer_and_earn': 'Aika & Sami',
      },
      'pcm': {
        'hub_settings': 'Hub Settings',
        'hub_desc': 'Manage your account security and belongings',
        'security_login': 'Security & Log in',
        'prefs_support': 'Preferences & Support',
        'language': 'Language',
        'help': 'Help',
        'log_out': 'Log Out',
        'generate_qr': 'Generate QR Code',
        'verified_account': 'Verified Account',
        'pin_settings': 'Pin Settings',
        'login_settings': 'Login Settings',
        'payment_settings': 'Payment Settings',
        'set_pin': 'Set Pin',
        'change_payment_pin': 'Change Payment Pin',
        'forget_payment_pin': 'Forget Payment Pin',
        'pay_with': 'Pay with',
        'change_password': 'Change Password',
        'forget_password': 'Forget Password',
        'auto_logout_settings': 'Auto Logout Settings',
        'login_with': 'Login with',
        'help_center': 'Help Center',
        'enable_scan_to_receive': 'Enable Scan to Receive',
        'refer_and_earn': 'Refer & Earn',
      }
    };
    return localizedStrings[state.languageCode]?[key] ?? localizedStrings['en']![key]!;
  }
}
