import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/router/route_constant.dart';

class SuccessScreen extends StatelessWidget {
  final String? amount;
  final String? recipientName;
  final String? recipientAccount;
  final String? reference;
  final String? channel;
  final String? type;

  const SuccessScreen({
    super.key,
    this.amount,
    this.recipientName,
    this.recipientAccount,
    this.reference,
    this.channel,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    // Extract all args
    final String? typ = type;
    final String? amot = amount;

    // Transfer
    final String? rName = recipientName;
    final String? rAccount = recipientAccount;

    // Deposit
    final String? ref = reference;
    final String? chl = channel;

    final textTheme = Theme.of(context).textTheme;
    debugPrint(type);
    debugPrint(recipientName);
    debugPrint(amount);
    debugPrint(reference);
    // -------------------------
    // TITLE BASED ON TYPE
    // -------------------------
    String titleText;
    if (typ == "transfer") {
      titleText = "Transfer Successful";
    } else if (typ == "deposit") {
      titleText = "Paystack Top-up Successful";
    } else {
      titleText = "Successful!";
    }

    // -------------------------
    // SUBTITLE / DETAILS
    // -------------------------
    Widget details;
    switch (type) {
      case "transfer":
        details = Text(
          "₦$amot has been transferred to $rAccount ($rName)",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: lightText),
        );
        break;

      case "deposit":
        details = Text(
          "₦$amount has been topped up from Paystack\nReference: $ref\nChannel: $chl",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: lightText),
        );
        break;

      default:
        details = Text(
          "Transaction successful.",
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: lightText),
        );
    }
    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30.h),

              // Success Icon
              SvgPicture.asset(successSvg, height: 100.h),

              SizedBox(height: 25.h),

              // TITLE
              Text(
                titleText,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: lightText,
                ),
              ),

              SizedBox(height: 20.h),

              // SUBTITLE DETAILS
              details,

              SizedBox(height: 30.h),

              // ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomButton(
                      buttonName: 'Share',
                      buttonColor: lightgray,
                      buttonTextColor: primaryColor,
                      onPressed: () {
                        String msg = "";

                        if (type == "transfer") {
                          msg =
                              "₦$amount was transferred to $recipientAccount ($recipientName).";
                        } else if (type == "deposit") {
                          msg =
                              "₦$amount top-up successful.\nReference: $reference\nChannel: $channel";
                        }

                        Share.share(msg, subject: "Transaction Successful");
                      },
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: CustomButton(
                      buttonName: 'View Details',
                      buttonColor: lightgray,
                      buttonTextColor: primaryColor,
                      onPressed: () =>
                          context.pushNamed(RouteList.bottomNavBar),
                    ),
                  ),
                ],
              ),

              Spacer(),

              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  buttonName: 'Done',
                  buttonColor: primaryColor,
                  buttonTextColor: Colors.white,
                  onPressed: () =>
                      context.pushNamed(RouteList.bottomNavBar),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
