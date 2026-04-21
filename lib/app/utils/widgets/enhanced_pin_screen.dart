import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../colors.dart';
import 'pin_input_widget.dart';

enum PinScreenType { set, verify, change, confirm }
enum InputFieldType { pin, password, amount }

class EnhancedPinScreen extends ConsumerWidget {
  final String title;
  final String subtitle;
  final PinScreenType type;
  final InputFieldType fieldType;
  final int inputLength;
  final String? existingPin;
  final String? hintText;
  final bool showKeypad;
  final bool lockoutEnabled;
  final double? minAmount;
  final String currency;
  final Function(String val)? onPinConfirmed;
  final Function(String val)? onPinComplete;
  final VoidCallback? onForgotPin;
  final VoidCallback? onBiometricAction;
  final VoidCallback? onSupportTap;
  final IconData? biometricIcon;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? keyColor;

  const EnhancedPinScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.type = PinScreenType.verify,
    this.fieldType = InputFieldType.pin,
    this.inputLength = 4,
    this.existingPin,
    this.hintText,
    this.showKeypad = true,
    this.lockoutEnabled = true,
    this.minAmount,
    this.currency = '₦',
    this.onPinConfirmed,
    this.onPinComplete,
    this.onForgotPin,
    this.onBiometricAction,
    this.onSupportTap,
    this.biometricIcon,
    this.showBackButton = true,
    this.backgroundColor,
    this.keyColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: backgroundColor ?? offWhiteBackground,
      appBar: AppBar(
        leading: showBackButton ? const BackButton(color: Colors.black) : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: PinInputWidget(
              title: title,
              subtitle: subtitle,
              type: type,
              fieldType: fieldType,
              inputLength: inputLength,
              existingPin: existingPin,
              hintText: hintText,
              showKeypad: showKeypad,
              lockoutEnabled: lockoutEnabled,
              currency: currency,
              onPinConfirmed: onPinConfirmed,
              onPinComplete: onPinComplete,
              onForgotPin: onForgotPin,
              onBiometricAction: onBiometricAction,
              onSupportTap: onSupportTap,
              biometricIcon: biometricIcon,
              keyColor: keyColor,
            ),
          ),
        ),
      ),
    );
  }
}