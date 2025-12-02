import 'package:bia/app/utils/router/page_transition/custom_slide_transition.dart';
import 'package:bia/app/utils/router/route_constant.dart';
import 'package:bia/feature/auth/presentation/pages/login.dart';
import 'package:bia/feature/dashboard/pages/vtu/data/data.dart';
import 'package:bia/feature/dashboard/pages/vtu/tv_cable/cable.dart';
import 'package:bia/feature/dashboard/pages/vtu/utility/utility.dart';
import 'package:flutter/material.dart';

import '../../../feature/auth/presentation/pages/create_account.dart';
import '../../../feature/auth/presentation/pages/create_account_phone.dart';
import '../../../feature/auth/presentation/pages/create_account_verify_otp.dart';
import '../../../feature/auth/presentation/pages/get_started.dart';
import '../../../feature/auth/presentation/pages/onboarding.dart';
import '../../../feature/auth/presentation/pages/splash_screen.dart';
import '../../../feature/auth/presentation/pages/welcome_back.dart';
import '../../../feature/bottom_nav_bar/bottom_nav.dart';
import '../../../feature/dashboard/pages/transaction_history.dart';
import '../../../feature/dashboard/pages/vtu/airtime/airtime.dart';
import '../../../feature/dashboard/send_money/input_transfer/amount.dart';
import '../../../feature/dashboard/send_money/input_transfer/send_money_transfer.dart';
import '../../../feature/dashboard/send_money/input_transfer/success.dart';
import '../../../feature/dashboard/send_money/scan_transfer/scanner.dart';
import '../../../feature/dashboard/send_money/scan_transfer/scanner_onboarding.dart';
import '../../../feature/dashboard/send_money/to_bank/transfer_to_banks.dart';
import '../../../feature/dashboard/send_money/top_up/add_money.dart';
import '../../../feature/settings/presentation/qr_code.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RouteGenerator {
  static dynamic route() {
    return {'Splash': (BuildContext context) => Splash()};
  }

  static Route<dynamic> appRoutes(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments;

    switch (routeSettings.name) {
      case RouteList.onBoardingScreen:
        return PageSlideTransition(
          page: (context) => OnBoardingScreen(),
          settings: RouteSettings(name: RouteList.onBoardingScreen),
        );

      case RouteList.loginScreen:
        return PageSlideTransition(
          page: (context) => LoginScreen(),
          settings: RouteSettings(name: RouteList.loginScreen),
        );

      case RouteList.createAccountScreen:
        return PageSlideTransition(
          page: (context) => CreateAccountScreen(),
          settings: RouteSettings(name: RouteList.createAccountScreen),
        );

      case RouteList.getStarted:
        return PageSlideTransition(
          page: (context) => GetStarted(),
          settings: RouteSettings(name: RouteList.getStarted),
        );

      case RouteList.bottomNavBar:
        return PageSlideTransition(
          page: (context) => BottomNavBar(),
          settings: RouteSettings(name: RouteList.bottomNavBar),
        );

      case RouteList.phoneRegScreen:
        return PageSlideTransition(
          page: (context) => PhoneRegScreen(),
          settings: RouteSettings(name: RouteList.phoneRegScreen),
        );

      case RouteList.welcomeBackScreen:
        return PageSlideTransition(
          page: (context) => WelcomeBackScreen(),
          settings: RouteSettings(name: RouteList.welcomeBackScreen),
        );

      case RouteList.airtime:
        return PageSlideTransition(
          page: (context) => Airtime(),
          settings: RouteSettings(name: RouteList.airtime),
        );

      case RouteList.data:
        return PageSlideTransition(
          page: (context) => Data(),
          settings: RouteSettings(name: RouteList.data),
        );

      case RouteList.cable:
        return PageSlideTransition(
          page: (context) => CableTv(),
          settings: RouteSettings(name: RouteList.cable),
        );

      case RouteList.topUp:
        return PageSlideTransition(
          page: (context) => AddMoney(),
          settings: RouteSettings(name: RouteList.topUp),
        );

      case RouteList.sendMoneyTransfer:
        return PageSlideTransition(
          page: (context) => SendMoneyTransfer(),
          settings: RouteSettings(name: RouteList.sendMoneyTransfer),
        );

      case RouteList.sendMoneyToBank:
        return PageSlideTransition(
          page: (context) => SendMoneyToBank(),
          settings: RouteSettings(name: RouteList.sendMoneyToBank),
        );

      case RouteList.amountPage:
        final args = routeSettings.arguments as Map<String, dynamic>?;

        return PageSlideTransition(
          page: (context) => AmountPage(
            controller: args?['controller'] ?? TextEditingController(),
            recipientName: args?['recipientName'] ?? '',
            recipientAccount: args?['recipientAccount'] ?? '',
          ),
          settings: RouteSettings(name: RouteList.amountPage),
        );

      case RouteList.successScreen:
        final args = routeSettings.arguments as Map<String, dynamic>?;

        if (args == null) {
          throw Exception(
            'SuccessScreen requires arguments: amount, recipientName, recipientAccount',
          );
        }

        return PageSlideTransition(
          page: (context) => SuccessScreen(
            amount: args['amount'],
            recipientName: args['recipientName'],
            recipientAccount: args['recipientAccount'],
          ),
          settings: RouteSettings(name: RouteList.successScreen),
        );

      case RouteList.scannerOnboarding:
        return PageSlideTransition(
          page: (context) => ScannerOnboarding(),
          settings: RouteSettings(name: RouteList.scannerOnboarding),
        );

      case RouteList.transactionHistory:
        return PageSlideTransition(
          page: (context) => TransactionHistory(),
          settings: RouteSettings(name: RouteList.transactionHistory),
        );

      case RouteList.createAccountVerifyOtpScreen:
        final args = routeSettings.arguments as Map<String, dynamic>?;

        return PageSlideTransition(
          page: (context) => CreateAccountVerifyOtpScreen(
            phone: args?['phone'] ?? '',
          ),
          settings: RouteSettings(name: RouteList.createAccountVerifyOtpScreen),
        );

      case RouteList.qrScannerScreen:
        return PageSlideTransition(
          page: (context) => QrScannerScreen(),
          settings: RouteSettings(name: RouteList.qrScannerScreen),
        );

      case RouteList.qrScreen:
        return PageSlideTransition(
          page: (context) => QrScreen(),
          settings: RouteSettings(name: RouteList.qrScreen),
        );

      case RouteList.electricity:
        return PageSlideTransition(
          page: (context) => Electricity(),
          settings: RouteSettings(name: RouteList.electricity),
        );

      default:
        return onUnknownRoute(const RouteSettings(name: '/Feature'));
    }
  }

  static Route onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Route not found: ${settings.name}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}