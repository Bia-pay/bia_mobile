import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:confetti/confetti.dart';
import 'colors.dart';
import 'custom_loader.dart';

enum UPopupType { success, error, warning, info }

class UPopup {
  static Future<T?> show<T>(
    BuildContext context, {
    required UPopupType type,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    Widget? content,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => UPopupDialog(
        type: type,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        content: content,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Convenience method for Success
  static Future<void> success(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) => show(
        context,
        type: UPopupType.success,
        title: title,
        message: message,
        confirmLabel: confirmLabel ?? "Done",
        onConfirm: onConfirm,
        barrierDismissible: barrierDismissible,
      );

  /// Convenience method for Errors
  static Future<void> error(
    BuildContext context, {
    String? title,
    required String message,
    String? confirmLabel,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) => show(
        context,
        type: UPopupType.error,
        title: title ?? "Error",
        message: message,
        confirmLabel: confirmLabel ?? "Close",
        onConfirm: onConfirm,
        barrierDismissible: barrierDismissible,
      );

  /// Convenience method for Confirmations
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) => show<bool>(
        context,
        type: UPopupType.warning,
        title: title,
        message: message,
        confirmLabel: confirmLabel ?? "Confirm",
        cancelLabel: cancelLabel ?? "Cancel",
        onConfirm: onConfirm,
        onCancel: onCancel,
        barrierDismissible: barrierDismissible,
      );

  /// Convenience method for Loading
  static void loading(
    BuildContext context, {
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UPopupDialog(
        type: UPopupType.info,
        title: "Please wait",
        message: message,
        isLoading: true,
      ),
    );
  }
}

class UPopupDialog extends StatefulWidget {
  final UPopupType type;
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final Widget? content;
  final bool isLoading;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const UPopupDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.content,
    this.isLoading = false,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<UPopupDialog> createState() => _UPopupDialogState();
}

class _UPopupDialogState extends State<UPopupDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.type == UPopupType.success) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor;
    IconData icon;
    
    switch (widget.type) {
      case UPopupType.success:
        mainColor = successColor;
        icon = Icons.check_rounded;
        break;
      case UPopupType.error:
        mainColor = errorColor;
        icon = Icons.close_rounded;
        break;
      case UPopupType.warning:
        mainColor = pendingColor;
        icon = Icons.priority_high_rounded;
        break;
      case UPopupType.info:
        mainColor = primaryColor;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.r)),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.all(28.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ICON HEADER
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                    child: widget.isLoading 
                      ? CustomLoader(color: mainColor)
                      : Icon(icon, color: mainColor, size: 32.sp),
                ),
                SizedBox(height: 24.h),

                /// CONTENT
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: lightText,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: lightSecondaryText,
                    fontSize: 14.sp,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                /// CUSTOM CONTENT (IF PROVIDED)
                if (widget.content != null) ...[
                  SizedBox(height: 20.h),
                  widget.content!,
                ],

                SizedBox(height: 32.h),

                /// ACTIONS
                if (!widget.isLoading)
                  Column(
                    children: [
                      /// PRIMARY BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                            if (widget.onConfirm != null) widget.onConfirm!();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.type == UPopupType.error ? errorColor : primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                          ),
                          child: Text(
                            widget.confirmLabel ?? "Continue",
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      
                      /// SECONDARY BUTTON (IF PROVIDED)
                      if (widget.cancelLabel != null) ...[
                        SizedBox(height: 8.h),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                              if (widget.onCancel != null) widget.onCancel!();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: lightSecondaryText,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Text(
                              widget.cancelLabel!,
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (widget.type == UPopupType.success)
          IgnorePointer(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
      ],
    );
  }
}
