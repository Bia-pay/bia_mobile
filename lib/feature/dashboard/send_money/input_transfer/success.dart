import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/utils/custom_button.dart';
import '../../../../app/utils/image.dart';
import '../../../../app/utils/router/route_constant.dart';
class SuccessScreen extends StatelessWidget {
  final String amount;
  final String recipientName;
  final String recipientAccount;

  const SuccessScreen({
    super.key,
    required this.amount,
    required this.recipientName,
    required this.recipientAccount,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              SvgPicture.asset(
                successSvg,
                fit: BoxFit.contain,
                height: 100.h,
              ),
              SizedBox(height: 20.h),
              Text(
                'Successful!',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: lightText,
                ),
              ),
              SizedBox(height: 20.h),

              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '₦$amount',
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' was sent to ',
                      style: textTheme.bodyMedium,
                    ),
                    TextSpan(
                      text: recipientName,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '\nSuccessful.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomButton(
                      buttonName: 'Share',
                      buttonColor: lightgray,
                      buttonTextColor: primaryColor,
                      onPressed: () {
                        final message = '₦$amount was sent to $recipientName ($recipientAccount). Successful transaction!';
                        Share.share(message, subject: 'Transaction Successful');
                      },
                    ),
                  ),
                  SizedBox(width: 20.w,),
                  Expanded(
                    child: CustomButton(
                        buttonName: 'View Details',
                        buttonColor: lightgray,
                        buttonTextColor: primaryColor,
                        onPressed: () => Navigator.pushNamed(context, RouteList.bottomNavBar)
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
                    onPressed: () => Navigator.pushNamed(context, RouteList.bottomNavBar)
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