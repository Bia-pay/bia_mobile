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

  /// Translation bridge for all UI strings across the application.
  String translate(String key) {
    final Map<String, Map<String, String>> localizedStrings = {
      'en': {
        // --- Navigation & Core ---
        'home': 'Home',
        'send_money': 'Send Money',
        'pay_bills': 'Pay Bills',
        'split_bill': 'Split Bill',
        'profile': 'Profile',
        'settings': 'Settings',

        // --- Dashboard & Hub ---
        'hub_settings': 'Settings',
        'hub_desc': 'Manage your account security and preferences',
        'security_login': 'Security & Login',
        'prefs_support': 'Preferences & Support',
        'more_options': 'More Options',
        'language': 'Language',
        'help': 'Help',
        'log_out': 'Log Out',
        'generate_qr': 'Generate QR Code',
        'verified_account': 'Verified Account',
        'total_balance': 'Total Balance',
        'virtual_account': 'Virtual Account',
        'account_number': 'Account Number',
        'bank_name': 'Bank Name',
        'quick_actions': 'Quick Actions',
        'recent_transactions': 'Recent Transactions',
        'view_all': 'View All',
        'deposit': 'Deposit',
        'withdrawal': 'Withdrawal',
        'bia_trike': 'Bia Trike',
        'bia_ai_assistant': 'Bia AI Assistant',
        'coming_soon': 'Coming Soon',

        // --- VTU Services ---
        'airtime': 'Airtime',
        'data': 'Data',
        'electricity': 'Electricity',
        'cable_tv': 'Cable TV',
        'select_network': 'Select Network',
        'phone_number': 'Phone Number',
        'select_plan': 'Select Plan',
        'meter_number': 'Meter Number',
        'smartcard_number': 'Smartcard Number',
        'confirm_recharge': 'Confirm Recharge',
        'confirm_purchase': 'Confirm Purchase',
        'pay_now': 'Pay Now',

        // --- Transfers & Payments ---
        'bia_to_bia': 'BIA to BIA',
        'to_bank': 'To Bank Account',
        'recipient': 'Recipient',
        'select_bank': 'Select Bank',
        'enter_amount': 'Enter Amount',
        'narration': 'Narration (Optional)',
        'continue_button': 'Continue',
        'confirm_transfer': 'Confirm Transfer',
        'enter_pin': 'Enter Transaction PIN',

        // --- Settings & Security ---
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

        // --- Common ---
        'notifications': 'Notifications',
        'mark_all_read': 'Mark All as Read',
        'success': 'Success',
        'failed': 'Failed',
        'copy': 'Copy',
        'copied': 'Copied to Clipboard',
        'search': 'Search',
        'save_as_beneficiary': 'Save as beneficiary',
      },
      'ha': {
        // --- Navigation & Core ---
        'home': 'Gida',
        'send_money': 'Tura Kudi',
        'pay_bills': 'Biya Kudi',
        'split_bill': 'Raba Kudi',
        'profile': 'Tarihi da Asusu',
        'settings': 'Saituna',

        // --- Dashboard & Hub ---
        'hub_settings': 'Saitunan Hub',
        'hub_desc': 'Sarrafa tsaro da abubuwan da kuke so na asusunku',
        'security_login': 'Tsaro da Shiga',
        'prefs_support': 'Gaba da Taimako',
        'more_options': 'Karin Zabi',
        'language': 'Yare',
        'help': 'Taimako',
        'log_out': 'Fita',
        'generate_qr': 'Sanya Lambar QR',
        'verified_account': 'Ingantaccen Asusu',
        'total_balance': 'Jimillar Ma\'auni',
        'virtual_account': 'Asusun Waya',
        'account_number': 'Lambar Asusu',
        'bank_name': 'Sunan Banki',
        'quick_actions': 'Ayyuka na Ciki',
        'recent_transactions': 'Mu\'amalolin Baya',
        'view_all': 'Duba Duka',
        'deposit': 'Sanya Kudi',
        'withdrawal': 'Cire Kudi',
        'bia_trike': 'Bia Trike',
        'bia_ai_assistant': 'Mataimakin Bia AI',
        'coming_soon': 'Zai Iso Ba Da Dadewa Ba',

        // --- VTU Services ---
        'airtime': 'Katin Waya',
        'data': 'Data',
        'electricity': 'Wutar Lantarki',
        'cable_tv': 'Kayan Kallo',
        'select_network': 'Zabi Hanyar Waya',
        'phone_number': 'Lambar Waya',
        'select_plan': 'Zabi Tsari',
        'meter_number': 'Lambar Mita',
        'smartcard_number': 'Lambar Katin Kallo',
        'confirm_recharge': 'Tabbatar da Sayen Katin',
        'confirm_purchase': 'Tabbatar da Sayen',
        'pay_now': 'Biya Yanzu',

        // --- Transfers & Payments ---
        'bia_to_bia': 'BIA zuwa BIA',
        'to_bank': 'Zuwa Asusun Banki',
        'recipient': 'Mai Karba',
        'select_bank': 'Zabi Banki',
        'enter_amount': 'Sanya Adadi',
        'narration': 'Bayanai (Zabi)',
        'continue_button': 'Ci Gaba',
        'confirm_transfer': 'Tabbatar da Turawa',
        'enter_pin': 'Sanya Lambar PIN',

        // --- Settings & Security ---
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

        // --- Common ---
        'notifications': 'Sadarwa',
        'mark_all_read': 'Sanya Duka a Karanta',
        'success': 'Nasarawa',
        'failed': 'Kasa',
        'copy': 'Kwafa',
        'copied': 'An Kwafa',
        'search': 'Nema',
        'save_as_beneficiary': 'Ajiye a matsayin mai karba',
      },
      'pcm': {
        // --- Navigation & Core ---
        'home': 'Home',
        'send_money': 'Send Money',
        'pay_bills': 'Pay Bills',
        'split_bill': 'Split Bill',
        'profile': 'Profile',
        'settings': 'Settings',

        // --- Dashboard & Hub ---
        'hub_settings': 'Hub Settings',
        'hub_desc': 'Manage your account security and belongings',
        'security_login': 'Security & Log in',
        'prefs_support': 'Preferences & Support',
        'more_options': 'More Options',
        'language': 'Language',
        'help': 'Help',
        'log_out': 'Log Out',
        'generate_qr': 'Generate QR Code',
        'verified_account': 'Verified Account',
        'total_balance': 'Total Balance',
        'virtual_account': 'Virtual Account',
        'account_number': 'Account Number',
        'bank_name': 'Bank Name',
        'quick_actions': 'Quick Actions',
        'recent_transactions': 'Recent Transactions',
        'view_all': 'View All',
        'deposit': 'Deposit',
        'withdrawal': 'Withdrawal',
        'bia_trike': 'Bia Trike',
        'bia_ai_assistant': 'Bia AI Assistant',
        'coming_soon': 'E Dey Come Soon',

        // --- VTU Services ---
        'airtime': 'Airtime',
        'data': 'Data',
        'electricity': 'Electricity',
        'cable_tv': 'Cable TV',
        'select_network': 'Select Network',
        'phone_number': 'Phone Number',
        'select_plan': 'Select Plan',
        'meter_number': 'Meter Number',
        'smartcard_number': 'Smartcard Number',
        'confirm_recharge': 'Confirm Recharge',
        'confirm_purchase': 'Confirm Purchase',
        'pay_now': 'Pay Now',

        // --- Transfers & Payments ---
        'bia_to_bia': 'BIA to BIA',
        'to_bank': 'To Bank Account',
        'recipient': 'Recipient',
        'select_bank': 'Select Bank',
        'enter_amount': 'Enter Amount',
        'narration': 'Narration (Optional)',
        'continue_button': 'Continue',
        'confirm_transfer': 'Confirm Transfer',
        'enter_pin': 'Enter Transaction PIN',

        // --- Settings & Security ---
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

        // --- Common ---
        'notifications': 'Notifications',
        'mark_all_read': 'Mark All as Read',
        'success': 'Success',
        'failed': 'Failed',
        'copy': 'Copy',
        'copied': 'Copied to Clipboard',
        'search': 'Search',
        'save_as_beneficiary': 'Save as beneficiary',
      }
    };
    return localizedStrings[state.languageCode]?[key] ?? localizedStrings['en']![key] ?? key;
  }
}

/// Extension on WidgetRef to easily translate strings: `ref.tr('key')`
extension WidgetRefTranslateExt on WidgetRef {
  String tr(String key) {
    return watch(appLocaleProvider.notifier).translate(key);
  }
}
