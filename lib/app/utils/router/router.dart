import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bia/app/utils/router/route_constant.dart';
import '../../../feature/ai_chat/ui/ai_chat_screen.dart';
import '../../../feature/ai_chat/ui/bia_language_onboarding.dart';
import '../../../feature/auth/interceptor/interceptor.dart';
import '../../../feature/auth/presentation/pages/create_account.dart';
import '../../../feature/auth/presentation/pages/create_account_phone.dart';
import '../../../feature/auth/presentation/pages/create_account_verify_otp.dart';
import '../../../feature/auth/presentation/pages/get_started.dart';
import '../../../feature/auth/presentation/pages/login.dart';
import '../../../feature/auth/presentation/pages/onboarding.dart';
import '../../../feature/auth/presentation/pages/splash_screen.dart';
import '../../../feature/auth/presentation/pages/welcome_back.dart';
import '../../../feature/auth/presentation/pages/forgot_password/forgot_password1.dart';
import '../../../feature/auth/presentation/pages/forgot_password/forgot_password2.dart';
import '../../../feature/bottom_nav_bar/bottom_nav.dart';
import '../../../feature/dashboard/pages/homepage.dart';
import '../../../feature/dashboard/pages/notification.dart';
import '../../../feature/dashboard/pages/send_money/input_transfer/amount.dart';
import '../../../feature/dashboard/pages/send_money/input_transfer/send_money_transfer.dart';
import '../../../feature/dashboard/pages/send_money/input_transfer/success.dart';
import '../../../feature/dashboard/pages/send_money/input_transfer/transaction_pin.dart';
import '../../../feature/dashboard/pages/send_money/scan_transfer/scanner.dart';
import '../../../feature/dashboard/pages/send_money/scan_transfer/scanner_onboarding.dart';
import '../../../feature/dashboard/pages/send_money/to_bank/bank_amount.dart';
import '../../../feature/dashboard/pages/send_money/to_bank/transfer_to_banks.dart';
import '../../../feature/dashboard/pages/send_money/top_up/add_money.dart';
import '../../../feature/dashboard/pages/send_money/top_up/topup_amount.dart';
import '../../../feature/dashboard/pages/transaction_details.dart';
import '../../../feature/dashboard/model/recent_transaction.dart';

import '../../../feature/settings/presentation/change_pin.dart';
import '../../../feature/settings/presentation/confirm_SetPin.dart';
import '../../../feature/settings/presentation/forgot_pin.dart';
import '../../../feature/settings/presentation/set_pin.dart';
import '../../../feature/dashboard/pages/transaction_history.dart';
import '../../../feature/dashboard/pages/vtu/airtime/airtime.dart';
import '../../../feature/dashboard/pages/vtu/data/data.dart';
import '../../../feature/dashboard/pages/vtu/tv_cable/cable.dart';
import '../../../feature/dashboard/pages/vtu/utility/utility.dart';
import '../../../feature/settings/presentation/change_password.dart';
import '../../../feature/settings/presentation/loginSettings/enable_login_fingerpint.dart';
import '../../../feature/settings/presentation/qr_code.dart';
import '../../../feature/qr_payment/presentation/qr_amount_entry_screen.dart';
import '../../../feature/qr_payment/presentation/qr_payment_review_screen.dart';
import '../../../feature/qr_payment/presentation/qr_deduction_pin_screen.dart';
import '../../../feature/qr_payment/presentation/qr_authorize_screen.dart';
import '../../../feature/settings/presentation/user_settings.dart';
import '../../../feature/settings/presentation/language_settings.dart';
import '../../../feature/settings/presentation/enable_login_fingerprint.dart';
import '../../socket/socket_test_page.dart';
import 'keyboard_observer.dart';
import '../../../feature/settings/presentation/auto_logout_settings.dart';

export '../../../feature/settings/presentation/change_password.dart'
    show NewPaymentPin;
void navigateWithUnfocus(BuildContext context, String route, {Object? extra}) {
  FocusManager.instance.primaryFocus?.unfocus();
  context.goNamed(route, extra: extra);
}
Page<dynamic> buildPageWithFadeTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}
class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,  // ← Allows ApiClient force-logout navigation
    observers: [DismissKeyboardOnNavigation()],

    debugLogDiagnostics: false,
    initialLocation: '/splash',
    redirect: (context, state) async {
      // 🔐 Check both centralized secure storage keys and Hive/legacy fallback keys
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final secureIsLoggedIn = (await secureStorage.read(key: 'is_logged_in')) == 'true';
      final secureUserId = await secureStorage.read(key: 'user_id');

      final authBox = Hive.box('authBox');
      final legacyIsLoggedIn = authBox.get('is_logged_in', defaultValue: false) == true;
      final legacyUserId = authBox.get('userId', defaultValue: '')?.toString() ?? '';

      final hasActiveSession = (secureIsLoggedIn && secureUserId != null && secureUserId.isNotEmpty) ||
                               (legacyIsLoggedIn && legacyUserId.isNotEmpty);

      final currentPath = state.uri.path;
      final isProtected = currentPath.startsWith('/home') ||
                          currentPath.startsWith('/transaction') ||
                          currentPath.startsWith('/send') ||
                          currentPath.startsWith('/amount') ||
                          currentPath.startsWith('/bankAmount') ||
                          currentPath.startsWith('/airtime') ||
                          currentPath.startsWith('/data') ||
                          currentPath.startsWith('/cable') ||
                          currentPath.startsWith('/electricity') ||
                          currentPath.startsWith('/top-up') ||
                          currentPath.startsWith('/socket-test');

      if (isProtected && !hasActiveSession) {
        return RouteList.loginScreen;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteList.splash,
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          context: context,
          state: state,
          child: const Splash(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteList.onBoardingScreen,
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          context: context,
          state: state,
          child: const OnBoardingScreen(),
        ),
      ),
      GoRoute(
        path: '/get-started',
        name: RouteList.getStarted,
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          context: context,
          state: state,
          child: const GetStarted(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: RouteList.loginScreen,
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/welcome-back',
        name: RouteList.welcomeBackScreen,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isSessionLock = extra?['isSessionLock'] as bool? ?? false;
          final forceHome = extra?['forceHome'] as bool? ?? false;
          return buildPageWithFadeTransition(
            context: context,
            state: state,
            child: WelcomeBackScreen(isSessionLock: isSessionLock, forceHome: forceHome),
          );
        },
      ),
      GoRoute(
        path: '/create-account',
        name: RouteList.createAccountScreen,
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          context: context,
          state: state,
          child: const CreateAccountScreen(),
        ),
      ),
      GoRoute(
        path: '/phone-registration',
        name: RouteList.phoneRegScreen,
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          context: context,
          state: state,
          child: const PhoneRegScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-otp',
        name: RouteList.createAccountVerifyOtpScreen,
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          context: context,
          state: state,
          child: CreateAccountVerifyOtpScreen(phone: state.extra as String? ?? ''),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteList.forgotPassword,
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          context: context,
          state: state,
          child: const ForgotPasswordScreen1(),
        ),
      ),
      GoRoute(
        path: '/forgot-password-reset',
        name: RouteList.forgotPasswordReset,
        builder: (context, state) =>
            ForgotPasswordScreen2(phoneNumber: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/home',
        name: RouteList.bottomNavBar,
        builder: (context, state) => const BottomNavBar(),
      ),
      GoRoute(
        path: '/transaction-history',
        name: RouteList.transactionHistory,
        builder: (context, state) => const TransactionHistory(),
      ),
      GoRoute(
        path: '/airtime',
        name: RouteList.airtime,
        builder: (context, state) => const Airtime(),
      ),
      GoRoute(
        path: '/data',
        name: RouteList.data,
        builder: (context, state) => const Data(),
      ),
      GoRoute(
        path: '/notification',
        name: RouteList.notification,
        builder: (context, state) => const NotificationPage(),
      ),
      GoRoute(
        path: '/cable',
        name: RouteList.cable,
        builder: (context, state) => const CableTv(),
      ),
      GoRoute(
        path: '/electricity',
        name: RouteList.electricity,
        builder: (context, state) => const Electricity(),
      ),
      GoRoute(
        path: '/top-up',
        name: RouteList.topUp,
        builder: (context, state) => const AddMoney(),
      ),
      GoRoute(
        path: '/send-money',
        name: RouteList.sendMoneyTransfer,
        builder: (context, state) => const SendMoneyTransfer(initialIndex: 0),
      ),
      GoRoute(
        path: '/send-by-tag',
        name: RouteList.sendByTag,
        builder: (context, state) => const SendMoneyTransfer(initialIndex: 1),
      ),
      GoRoute(
        path: '/send-to-bank',
        name: RouteList.sendMoneyToBank,
        builder: (context, state) => const SendMoneyToBank(),
      ),  GoRoute(
        path: '/transactionDetailsScreen',
        name: RouteList.transactionDetailsScreen,
        builder: (context, state) => TransactionDetailsScreen(transaction: state.extra as TransactionItem),

      ),
      GoRoute(
        path: '/amount',
        name: RouteList.amountPage,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return AmountPage(
            controller: args['controller'] ?? TextEditingController(),
            recipientName: args['recipientName'] ?? '',
            recipientAccount: args['recipientAccount'] ?? '',
            initialAmount: args['amount'],
            initialNarration: args['narration'],
          );
        },
      ),
      GoRoute(
        path: '/bankAmountPage',
        name: RouteList.bankAmountPage,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};

          return BankAmountPage(
            controller: args['controller'] ?? TextEditingController(),
            recipientName: args['recipientName'] ?? '',
            recipientAccount: args['recipientAccount'] ?? '',
            bankCode: args['bankCode'] ?? '', // ✅ ADD
            bankName: args['bankName'] ?? '', // ✅ ADD
            recipientIconPath: args['recipientIconPath'],
          );
        },
      ),
      GoRoute(
        path: '/transaction-pin',
        name: RouteList.transactionPin,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;

          return TransactionPin(
            recipientAccount: extra['recipientAccount'],
            recipientName: extra['recipientName'],
            amount: (extra['amount'] as num).toDouble(),
            type: extra['type'],
            saveAsBeneficiary: false,
            meta: extra['meta'], // ✅ THIS LINE IS MISSING IN YOUR CODE
          );
        },
      ),
      GoRoute(
        path: '/success',
        name: RouteList.successScreen,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return SuccessScreen(
            type: args['type'] ?? '',
            amount: args['amount'] ?? '',
            recipientName: args['recipientName'] ?? '',
            recipientAccount: args['recipientAccount'] ?? '',
            reference: args['reference'] ?? '',
            channel: args['channel'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/scanner-onboarding',
        name: RouteList.scannerOnboarding,
        builder: (context, state) {
          final bool completed = Hive.box('authBox').get('qr_onboarding_completed', defaultValue: false);
          if (completed) {
            return const QrScannerScreen();
          }
          return const ScannerOnboarding();
        },
      ),
      GoRoute(
        path: '/qr-scanner',
        name: RouteList.qrScannerScreen,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/qr-amount',
        name: RouteList.qrAmountEntryScreen,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final receiverAccount = extra['account'] as String? ?? '';
          final isCollectMode = extra['isCollectMode'] as bool? ?? false;
          return QrAmountEntryScreen(
            receiverAccount: receiverAccount,
            isCollectMode: isCollectMode,
          );
        },
      ),
      GoRoute(
        path: '/qr-deduction',
        name: RouteList.qrDeductionPinScreen,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final ownerAccount = extra['ownerAccount'] as String? ?? '';
          final amount = extra['amount'] as double? ?? 0.0;
          final narration = extra['narration'] as String? ?? '';
          return QrDeductionPinScreen(
            ownerAccount: ownerAccount,
            amount: amount,
            narration: narration,
          );
        },
      ),
      GoRoute(
        path: '/qr-review',
        name: RouteList.qrPaymentReviewScreen,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return QrPaymentReviewScreen(
            requestId: extra['requestId'],
            receiverName: extra['receiverName'],
            amount: (extra['amount'] as num).toDouble(),
          );
        },
      ),
      GoRoute(
        path: '/qr-code',
        name: RouteList.qrScreen,
        builder: (context, state) => const QrScreen(),
      ),
      GoRoute(
        path: '/set-pin',
        name: RouteList.setTransactionPin,
        builder: (context, state) => const SetPin(),
      ),
      //Enter OLD PIN
      GoRoute(
        path: '/change-pin',
        name: RouteList.changePaymentPin,
        builder: (context, state) => const ChangePaymentPin(),
      ),

      // Enter NEW PIN (after old pin)
      GoRoute(
        path: '/change-pin/new',
        name: RouteList.changeNewPaymentPin,
        builder: (context, state) {
          final oldPin = state.extra as String;
          return SetNewPin(oldPin: oldPin);
        },
      ),

      // Confirm NEW PIN
      GoRoute(
        path: '/change-pin/confirm',
        name: RouteList.confirmChangeNewPaymentPin,
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          return ConfirmSetNewPin(
            oldPin: data['oldPin']!,
            newPin: data['newPin']!,
          );
        },
      ),
      GoRoute(
        path: '/changePin',
        name: RouteList.restoreNewPin,
        builder: (context, state) {
          return const RestoreNewPin();
        },
      ),
      GoRoute(
        path: '/confirmChangeNewPin',
        name: RouteList.confirmRestoreNewPin,
        builder: (context, state) {
          final newPin = state.extra as String;

          return ConfirmRestoreNewPin( newPin: newPin,);
        },
      ),
      GoRoute(
        path: '/confirm-SetPin',
        name: RouteList.confirmSetPin,
        builder: (context, state) {
          final originalPin = state.extra as String;

          return ConfirmSetPin(originalPin: originalPin);
        },
      ),

      GoRoute(
        name: RouteList.forgotPin,
        path: '/forgot-pin',
        builder: (context, state) => const ForgotPinScreen(phone: ''),
      ),
      GoRoute(
        path: '/deposit-screen',
        name: RouteList.depositScreen,
        builder: (context, state) => const TopUpAmountPage(),
      ),
      GoRoute(
        path: '/enable-login-fingerprint',
        name: RouteList.enableLoginFingerprint,
        builder: (context, state) => const EnableLoginFingerprint(),
      ),
      GoRoute(
        path: '/enable-transaction-fingerprint',
        name: RouteList.enableTransactionPinFingerprint,
        builder: (context, state) => const EnableTransactionPinFingerprint(),
      ),
      GoRoute(
        path: '/socket-test',
        name: 'socketTest',
        builder: (context, state) => const SocketTestPage(),
      ),
      GoRoute(
        path: RouteList.aiChat,
        name: RouteList.aiChat,
        builder: (context, state) => const AiChatScreen(),
      ),
      GoRoute(
        path: RouteList.biaLanguageOnboarding,
        name: RouteList.biaLanguageOnboarding,
        builder: (context, state) => const BiaLanguageOnboarding(),
      ),
      GoRoute(
        path: RouteList.userSettings,
        name: RouteList.userSettings,
        builder: (context, state) => const UserSettingsScreen(),
      ),
      GoRoute(
        path: RouteList.languageSettings,
        name: RouteList.languageSettings,
        builder: (context, state) => const LanguageSettingsScreen(),
      ),
      GoRoute(
        path: RouteList.autoLogoutSettings,
        name: RouteList.autoLogoutSettings,
        builder: (context, state) => const AutoLogoutSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Route not found: ${state.uri}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
