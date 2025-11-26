import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';

class ToastHelper {
  /// Show a reusable sliding toast
  static void showToast({
    required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    Color iconColor = Colors.red,
    Duration animationDuration = const Duration(milliseconds: 600),
    Duration displayDuration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.top,
  }) {
    InteractiveToast.slide(
      context: context,
      leading: Icon(icon, color: iconColor),
      title: Text(
        message,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      toastStyle: const ToastStyle(titleLeadingGap: 10),
      toastSetting: SlidingToastSetting(
        maxWidth: 370.w,
        animationDuration: animationDuration,
        displayDuration: displayDuration,
        showProgressBar: false,
        toastStartPosition: position,
        toastAlignment: position == ToastPosition.top
            ? Alignment.topCenter
            : Alignment.bottomCenter,
      ),
    );
  }
}
