// TransactionPin widget
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/keypad.dart';

class BankTransactionPin extends ConsumerStatefulWidget {
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final bool saveAsBeneficiary;
  final String bankCode;
  final String bankName;

  const BankTransactionPin({
    super.key,
    required this.recipientAccount,
    required this.recipientName,
    required this.amount,
    required this.saveAsBeneficiary,
    required this.bankCode,
    required this.bankName,
  });

  @override
  ConsumerState<BankTransactionPin> createState() =>
      _BankTransactionPinState();
}

class _BankTransactionPinState
    extends ConsumerState<BankTransactionPin> {

  String pin = "";
  bool showPinWarning = false;

  void addDigit(String value) {
    if (pin.length >= 4) return;

    setState(() {
      pin += value;
      showPinWarning = false;
    });
  }

  void removeDigit() {
    if (pin.isEmpty) return;

    setState(() {
      pin = pin.substring(0, pin.length - 1);
    });
  }

  Future<void> _processTransfer() async {
    if (pin.length != 4) {
      setState(() => showPinWarning = true);
      return;
    }

    final controller =
    ref.read(dashboardControllerProvider.notifier);

    final response = await controller.sendMoneyToBank(
      context,
      accountNumber: widget.recipientAccount,
      bankCode: widget.bankCode,
      bankName: widget.bankName,
      amount: widget.amount.toStringAsFixed(2),
      narration: "Bank Transfer",
      pin: pin,
      saveBeneficiary: widget.saveAsBeneficiary,
    );

    if (response != null && response.responseSuccessful) {

      final reference = response.responseBody?.txnRef ??
          response.responseBody?.paymentRef ??
          "";

      context.pushNamed(
        RouteList.successScreen,
        extra: {
          "type": "bank_transfer",
          "amount": widget.amount.toStringAsFixed(2),
          "recipientName": widget.recipientName,
          "recipientAccount": widget.recipientAccount,
          "reference": reference,
          "channel": widget.bankName,
        },
      );
    }else {
      final msg =
          response?.responseMessage ?? "Transfer failed. Check your PIN.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleForgotPin() async {
    try {
      EasyLoading.show(status: "Sending OTP...");

      final controller =
      ref.read(dashboardControllerProvider.notifier);

      final result =
      await controller.forgotPaymentPin(context);

      EasyLoading.dismiss();

      if (!mounted) return;

      // ✅ PROPER NULL CHECK
      if (result != null && result.responseSuccessful == true) {
        context.pushNamed(RouteList.forgotPin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?.responseMessage ?? "Failed to send OTP"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: lightBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: lightText,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 50.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 60.h),

            Container(
              padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withOpacity(0.4),
                    primaryColor,
                    primaryColor.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.all(Radius.circular(10.r)),
              ),
              child: Icon(Icons.lock, color: Colors.white, size: 30.sp),
            ),
            Text(
              'Enter Transaction PIN',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 30.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < pin.length;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: primaryColor,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (showPinWarning)
              Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Text(
                  "Enter a valid 4-digit PIN",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),

            SizedBox(height: 70.h),

            Expanded(
              child: CustomGridKeypad(
                onNumberPressed: addDigit,

                leftAction: ActionKey(
                  child: const Icon(Icons.check, color: Colors.white),
                  backgroundColor: primaryColor,
                  onTap: _processTransfer,
                ),

                rightAction: ActionKey(
                  child: Icon(Icons.backspace, color: primaryColor),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  onTap: removeDigit,
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: GestureDetector(
                onTap: () => _handleForgotPin(),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Forget Pin?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: lightText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}