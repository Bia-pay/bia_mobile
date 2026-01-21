import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bia/core/__core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../app/utils/custom_button.dart';
import '../../../../../app/utils/image.dart';
import '../../../../../app/utils/router/route_constant.dart';

class SuccessScreen extends StatefulWidget {
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
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  Future<File> _captureAndSave() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;

    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/transaction_success.png');
    await file.writeAsBytes(pngBytes);

    return file;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final initiatedTime = "10:12 AM";
    final processingTime = "10:12 AM";
    final completedTime = "10:13 AM";

    String titleText;
    if (widget.type == "transfer") {
      titleText = "Transfer Successful";
    } else if (widget.type == "deposit") {
      titleText = "Paystack Top-up Successful";
    } else {
      titleText = "Successful!";
    }

    Widget details;
    switch (widget.type) {
      case "transfer":
        details = RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: textTheme.bodyLarge?.copyWith(color: lightText),
            children: [
              const TextSpan(text: "The amount of "),
              TextSpan(
                text: "₦${widget.amount}",
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: darkBackground,
                ),
              ),
              TextSpan(
                text: " has been transferred to ",
                style: textTheme.bodyLarge?.copyWith(color: lightText),
              ),
              TextSpan(
                text: "${widget.recipientAccount} (${widget.recipientName})",
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: darkBackground,
                ),
              ),
            ],
          ),
        );
        break;

      case "deposit":
        details = Text(
          "₦${widget.amount} has been topped up from Paystack\nReference: ${widget.reference}\nChannel: ${widget.channel}",
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
      backgroundColor: Colors.white, // white background
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            /// ================= CAPTURED AREA ONLY =================
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                width: double.infinity,
                color: Colors.white, // ensure white bg in image
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20.h),

                    SvgPicture.asset(successs, height: 140.h),

                    SizedBox(height: 20.h),

                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: successColor,
                        fontSize: 22.spMin,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '₦${widget.amount}',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: darkBackground,
                        fontSize: 37.spMin,
                      ),
                    ),

                    SizedBox(height: 10.h),
                    // Text(
                    //   "The beneficiary should receive the money within 5 minutes, depending on their bank.",
                    //   textAlign: TextAlign.center,
                    //   style: textTheme.bodyMedium?.copyWith(
                    //     fontWeight: FontWeight.w800,
                    //     color: lightSecondaryText,
                    //     fontSize: 12.spMin,
                    //   ),
                    // ),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     _statusItem(
                    //       context,
                    //       title: "Initiated",
                    //       time: initiatedTime,
                    //       icon: Icons.check_circle,
                    //       color: successColor,
                    //     ),
                    //     _statusItem(
                    //       context,
                    //       title: "Processing",
                    //       time: processingTime,
                    //       icon: Icons.check_circle,
                    //       color: successColor,
                    //     ),
                    //     _statusItem(
                    //       context,
                    //       title: widget.type == "failed"
                    //           ? "Failed"
                    //           : widget.type == "pending"
                    //           ? "Pending"
                    //           : "Completed",
                    //       time: completedTime,
                    //       icon: widget.type == "failed"
                    //           ? Icons.cancel
                    //           : widget.type == "pending"
                    //           ? Icons.schedule
                    //           : Icons.check_circle,
                    //       color: widget.type == "failed"
                    //           ? errorColor
                    //           : widget.type == "pending"
                    //           ? pendingColor
                    //           : successColor,
                    //     ),
                    //   ],
                    // ),
                    //
                    // SizedBox(height: 30.h),

                    // details,
                  ],
                ),
              ),
            ),

            /// ================= NOT CAPTURED =================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      buttonName: 'Share',
                      icon: Icons.share,
                      buttonColor: lightgray,
                      buttonTextColor: darkBorderColor,
                      buttonBorderColor: darkBorderColor,
                      onPressed: () async {
                        final file = await _captureAndSave();
                        await Share.shareXFiles([
                          XFile(file.path),
                        ], text: "Transaction Successful");
                      },
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: CustomButton(
                      buttonName: 'Download',
                      icon: Icons.download,
                      buttonColor: lightgray,
                      buttonTextColor: darkBorderColor,
                      buttonBorderColor: darkBorderColor,
                      onPressed: () =>
                          context.pushNamed(RouteList.bottomNavBar),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: offWhiteBackground,
                border: Border(top: BorderSide(color: successColor, width: 2)),
                borderRadius: BorderRadius.all(Radius.circular(10.r)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TO',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: lightSecondaryText,
                        ),
                      ),
                      Text(
                        '${widget.recipientName}',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: darkBackground,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaction ID',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: lightSecondaryText,
                        ),
                      ),
                      Text(
                        '#1213213121',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: darkBackground,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date & Time',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: lightSecondaryText,
                        ),
                      ),
                      Text(
                        '12 Jan 2024 03.20 am',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: darkBackground,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Charges',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: lightSecondaryText,
                        ),
                      ),
                      Text(
                        'Free',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: darkBackground,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  buttonName: 'Done',
                  buttonColor: primaryColor,
                  buttonTextColor: Colors.white,
                  onPressed: () => context.pushNamed(RouteList.bottomNavBar),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _statusItem(
    BuildContext context, {
    required String title,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(height: 6.h),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: lightText,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10.sp,
              color: lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
