import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bia/app/utils/router/route_constant.dart';
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
import '../../../feature/dashboard/pages/send_money/input_transfer/amount.dart';
import '../../../feature/dashboard/pages/send_money/input_transfer/send_money_transfer.dart';
import '../../../feature/dashboard/pages/send_money/input_transfer/success.dart';
import '../../../feature/dashboard/pages/send_money/scan_transfer/scanner.dart';
import '../../../feature/dashboard/pages/send_money/scan_transfer/scanner_onboarding.dart';
import '../../../feature/dashboard/pages/send_money/to_bank/transfer_to_banks.dart';
import '../../../feature/dashboard/pages/send_money/top_up/add_money.dart';
import '../../../feature/dashboard/pages/send_money/top_up/topup_amount.dart';
import '../../../feature/dashboard/pages/set_pin.dart';
import '../../../feature/dashboard/pages/transaction_history.dart';
import '../../../feature/dashboard/pages/vtu/airtime/airtime.dart';
import '../../../feature/dashboard/pages/vtu/data/data.dart';
import '../../../feature/dashboard/pages/vtu/tv_cable/cable.dart';
import '../../../feature/dashboard/pages/vtu/utility/utility.dart';
import '../../../feature/settings/presentation/change_password.dart';
import '../../../feature/settings/presentation/qr_code.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: false,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', name: RouteList.splash, builder: (context, state) => const Splash()),
      GoRoute(path: '/onboarding', name: RouteList.onBoardingScreen, builder: (context, state) => const OnBoardingScreen()),
      GoRoute(path: '/get-started', name: RouteList.getStarted, builder: (context, state) => const GetStarted()),
      GoRoute(path: '/login', name: RouteList.loginScreen, builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/welcome-back', name: RouteList.welcomeBackScreen, builder: (context, state) => const WelcomeBackScreen()),
      GoRoute(path: '/create-account', name: RouteList.createAccountScreen, builder: (context, state) => const CreateAccountScreen()),
      GoRoute(path: '/phone-registration', name: RouteList.phoneRegScreen, builder: (context, state) => const PhoneRegScreen()),
      GoRoute(path: '/verify-otp', name: RouteList.createAccountVerifyOtpScreen, builder: (context, state) => CreateAccountVerifyOtpScreen(phone: state.extra as String? ?? '')),
      GoRoute(path: '/forgot-password', name: RouteList.forgotPassword, builder: (context, state) => const ForgotPasswordScreen1()),
      GoRoute(path: '/forgot-password-reset', name: RouteList.forgotPasswordReset, builder: (context, state) => ForgotPasswordScreen2(phoneNumber: state.extra as String? ?? '')),
      GoRoute(path: '/home', name: RouteList.bottomNavBar, builder: (context, state) => const BottomNavBar()),
      GoRoute(path: '/transaction-history', name: RouteList.transactionHistory, builder: (context, state) => const TransactionHistory()),
      GoRoute(path: '/airtime', name: RouteList.airtime, builder: (context, state) => const Airtime()),
      GoRoute(path: '/data', name: RouteList.data, builder: (context, state) => const Data()),
      GoRoute(path: '/cable', name: RouteList.cable, builder: (context, state) => const CableTv()),
      GoRoute(path: '/electricity', name: RouteList.electricity, builder: (context, state) => const Electricity()),
      GoRoute(path: '/top-up', name: RouteList.topUp, builder: (context, state) => const AddMoney()),
      GoRoute(path: '/send-money', name: RouteList.sendMoneyTransfer, builder: (context, state) => const SendMoneyTransfer()),
      GoRoute(path: '/send-to-bank', name: RouteList.sendMoneyToBank, builder: (context, state) => const SendMoneyToBank()),
      GoRoute(path: '/amount', name: RouteList.amountPage, builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return AmountPage(controller: args['controller'] ?? TextEditingController(), recipientName: args['recipientName'] ?? '', recipientAccount: args['recipientAccount'] ?? '');
      }),
      GoRoute(path: '/success', name: RouteList.successScreen, builder: (context, state) {
        final args = state.extra as Map<String, dynamic>? ?? {};
        return SuccessScreen(type: args['type'] ?? '', amount: args['amount'] ?? '', recipientName: args['recipientName'] ?? '', recipientAccount: args['recipientAccount'] ?? '', reference: args['reference'] ?? '', channel: args['channel'] ?? '');
      }),
      GoRoute(path: '/scanner-onboarding', name: RouteList.scannerOnboarding, builder: (context, state) => const ScannerOnboarding()),
      GoRoute(path: '/qr-scanner', name: RouteList.qrScannerScreen, builder: (context, state) => const QrScannerScreen()),
      GoRoute(path: '/qr-code', name: RouteList.qrScreen, builder: (context, state) => const QrScreen()),
      GoRoute(path: '/change-pin', name: RouteList.changePaymentPin, builder: (context, state) => const ChangePaymentPin()),
      GoRoute(path: '/set-pin', name: RouteList.setTransactionPin, builder: (context, state) => const SetPin()),
      GoRoute(path: '/deposit-screen', name: RouteList.depositScreen, builder: (context, state) => const TopUpAmountPage()),
    ],
    errorBuilder: (context, state) => Scaffold(body: SafeArea(child: Center(child: Text('Route not found: ${state.uri}', textAlign: TextAlign.center)))),
  );
}
