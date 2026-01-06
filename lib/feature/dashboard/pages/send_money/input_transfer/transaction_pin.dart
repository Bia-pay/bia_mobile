// TransactionPin widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/utils/colors.dart';
import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/router/route_constant.dart';
import '../../../../../app/utils/widgets/pin_field.dart';
import '../../../dashboardcontroller/dashboardcontroller.dart';
import '../../../widgets/keypad.dart';

// class TransactionPin extends ConsumerWidget {
//   final String recipientAccount;
//   final String recipientName;
//   final double amount;
//   final bool saveAsBeneficiary;
//
//   const TransactionPin({
//     super.key,
//     required this.recipientAccount,
//     required this.recipientName,
//     required this.amount,
//     required this.saveAsBeneficiary,
//   });
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final TextEditingController pinController = TextEditingController();
//
//     return Column(
//       children: [
//         SizedBox(
//           width: 250.w,
//           child: AppPinCodeField(
//             controller: pinController,
//             length: 4,
//             fillColor: keyAColor,
//             inactiveColor: keyAColor,
//             activeColor: primaryColor,
//             selectedColor: primaryColor,
//           ),
//         ),
//         SizedBox(height: 20.h),
//         SizedBox(
//           width: double.infinity,
//           child: CustomButton(
//             buttonName: 'Send Money',
//             buttonColor: primaryColor,
//             buttonTextColor: Colors.white,
//             onPressed: () async {
//               final pin = pinController.text.trim();
//
//               if (pin.length != 4 || int.tryParse(pin) == null) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text("PIN must be 4 digits"),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//                 return;
//               }
//
//               final authController = ref.read(dashboardControllerProvider.notifier);
//
//               // Build request body
//               final body = {
//                 'account': recipientAccount.trim(),
//                 'amount': amount.toStringAsFixed(2),
//                 'narration': 'Transfer',
//                 'pin': pin,
//                 'save': saveAsBeneficiary.toString(),
//               };
//
//               final response = await authController.sendMoney(body);
//
//               if (response.responseSuccessful) {
//                 if (!context.mounted) return;
//
//                 Navigator.pop(context); // close PIN screen
//                 context.pushNamed(
//                   RouteList.successScreen,
//                   extra: {
//                     "type": "transfer",
//                     "amount": amount.toStringAsFixed(2),
//                     "recipientName": recipientName,
//                     "recipientAccount": recipientAccount,
//                     "reference": "",
//                     "channel": "",
//                   },
//                 );
//               } else {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(response.responseMessage ??
//                         "Transfer failed. Check your PIN."),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }


class TransactionPin extends ConsumerStatefulWidget {
  final String recipientAccount;
  final String recipientName;
  final double amount;
  final bool saveAsBeneficiary;

  const TransactionPin({
    super.key,
    required this.recipientAccount,
    required this.recipientName,
    required this.amount, required this.saveAsBeneficiary,
  });


  @override
  ConsumerState<TransactionPin> createState() => _TransactionPinState();
}

class _TransactionPinState extends ConsumerState<TransactionPin> {
  String pin = "";
  bool showPinWarning = false;
  late final TextEditingController pinController;

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  void addDigit(String value) {
    if (pin.length >= 4) return;
    setState(() {
      pin += value;
      pinController.text = pin; // update controller
      showPinWarning = false;
    });
  }

  void removeDigit() {
    if (pin.isEmpty) return;
    setState(() {
      pin = pin.substring(0, pin.length - 1);
      pinController.text = pin; // update controller
    });
  }

  Future<void> _processTransfer() async {
    if (pin.length != 4) {
      setState(() => showPinWarning = true);
      return;
    }

    final controller = ref.read(dashboardControllerProvider.notifier);

    final response = await controller.sendMoney(
      context,
      widget.recipientAccount,
      widget.amount.toStringAsFixed(2),
      'Transfer',
      pin,
      save: widget.saveAsBeneficiary,
    );

    if (response != null && response.responseSuccessful) {
      context.pushNamed(
        RouteList.successScreen,
        extra: {
          "type": "transfer",
          "amount": widget.amount.toStringAsFixed(2),
          "recipientName": widget.recipientName,
          "recipientAccount": widget.recipientAccount,
          "reference": "",
          "channel": "",
        },
      );
    } else {
      // ❌ Show error if PIN is wrong or transfer failed
      final msg =
          response?.responseMessage ??
              "Transfer failed. Check your PIN.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: offWhiteBackground,
      appBar: AppBar(
        title: Text(
          'Enter Transaction PIN',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: offWhiteBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: lightText,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 50.h),
            Text(
              'Enter PIN',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.h),
            AppPinCodeField(
              controller: pinController,
              length: 4,
              fillColor: keyAColor,
              inactiveColor: keyAColor,
              activeColor: primaryColor,
              selectedColor: primaryColor,
            ),
            if (showPinWarning)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text(
                  "PIN must be 4 digits",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: 50.h),
            Expanded(
              child: CustomGridKeypad(
                onKeyPressed: (key) {
                  if (key == "x") removeDigit();
                  else if (key == "ok") _processTransfer();
                  else addDigit(key);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
