import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../colors.dart';
import 'pin_field.dart';
import 'custom_keypad.dart';

enum PinScreenType { set, confirm, verify, change }
enum InputFieldType { pin, password, amount }

class EnhancedPinScreen extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final PinScreenType type;
  final InputFieldType fieldType;
  final Function(String pin)? onPinComplete;
  final Function(String pin)? onPinConfirmed;
  final String? existingPin; // For verification
  final bool showBackButton;
  final Widget? customAppBar;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final int inputLength;
  final String? hintText;
  final String? errorMessage;
  final bool obscureText;
  final bool showKeypad;
  final double? minAmount;
  final String? currency;

  const EnhancedPinScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.type = PinScreenType.set,
    this.fieldType = InputFieldType.pin,
    this.onPinComplete,
    this.onPinConfirmed,
    this.existingPin,
    this.showBackButton = true,
    this.customAppBar,
    this.backgroundColor,
    this.padding,
    this.inputLength = 4,
    this.hintText,
    this.errorMessage,
    this.obscureText = true,
    this.showKeypad = true,
    this.minAmount,
    this.currency = '₦',
  });

  @override
  ConsumerState<EnhancedPinScreen> createState() => _EnhancedPinScreenState();
}

class _EnhancedPinScreenState extends ConsumerState<EnhancedPinScreen> {
  final TextEditingController pinController = TextEditingController();
  bool showMinWarning = false;
  bool isConfirm = false;
  String firstPin = '';

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  void _onKeypadInput(String value) {
    if (!mounted) return;
    setState(() {
      if (value == "delete") {
        if (widget.fieldType == InputFieldType.amount) {
          _removeAmountDigit();
        } else {
          if (pinController.text.isNotEmpty) {
            pinController.text = pinController.text.substring(0, pinController.text.length - 1);
          }
        }
      } else if (value == "submit") {
        _handleSubmit();
      } else {
        if (widget.fieldType == InputFieldType.amount) {
          _addAmountDigit(value);
        } else {
          if (pinController.text.length < widget.inputLength) {
            pinController.text += value;
          }
        }
      }
      _checkMinLimit();
    });
  }

  void _addAmountDigit(String digit) {
    String current = pinController.text.replaceAll(widget.currency!, '');
    
    if (current == "0") {
      current = digit;
    } else {
      current += digit;
    }
    
    pinController.text = '${widget.currency}$current';
  }

  void _removeAmountDigit() {
    String current = pinController.text.replaceAll(widget.currency!, '');
    if (current.isNotEmpty) {
      current = current.substring(0, current.length - 1);
    }
    if (current.isEmpty) {
      current = "0";
    }
    pinController.text = '${widget.currency}$current';
  }

  void _handleSubmit() {
    if (!mounted) return;

    if (widget.fieldType == InputFieldType.amount) {
      final numericValue = num.tryParse(pinController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final minAmount = widget.minAmount ?? 50;
      if (numericValue < minAmount) {
        setState(() => showMinWarning = true);
        return;
      }
    } else {
      // For password fields, allow any length > 0, for PIN fields, enforce exact length
      final minLength = widget.fieldType == InputFieldType.password ? 1 : widget.inputLength;
      final exactLength = widget.fieldType == InputFieldType.pin;

      if (exactLength && pinController.text.length != widget.inputLength) {
        setState(() => showMinWarning = true);
        return;
      } else if (!exactLength && pinController.text.length < minLength) {
        setState(() => showMinWarning = true);
        return;
      }
    }

    switch (widget.type) {
      case PinScreenType.set:
        _handleSetPin();
        break;
      case PinScreenType.verify:
        _handleVerifyPin();
        break;
      case PinScreenType.change:
        _handleChangePin();
        break;
      case PinScreenType.confirm:
        _handleConfirmPin();
        break;
    }
  }

  void _handleSetPin() {
    if (!isConfirm) {
      // First step: Set PIN
      firstPin = pinController.text;
      pinController.clear();
      setState(() {
        isConfirm = true;
        showMinWarning = false;
      });
    } else {
      // Second step: Confirm PIN
      if (pinController.text == firstPin) {
        widget.onPinConfirmed?.call(pinController.text);
        if (mounted) Navigator.pop(context);
      } else {
        _showError("PINs do not match. Try again!");
        pinController.clear();
      }
    }
  }

  void _handleVerifyPin() {
    if (widget.existingPin != null && pinController.text == widget.existingPin) {
      widget.onPinComplete?.call(pinController.text);
    } else {
      _showError("Incorrect PIN. Please try again.");
      pinController.clear();
    }
  }

  void _handleChangePin() {
    // Similar to set PIN but might need existing PIN verification first
    _handleSetPin();
  }

  void _handleConfirmPin() {
    widget.onPinComplete?.call(pinController.text);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _checkMinLimit() {
    if (widget.fieldType == InputFieldType.password) {
      showMinWarning = pinController.text.isEmpty && pinController.text.isNotEmpty;
    } else if (widget.fieldType == InputFieldType.amount) {
      final numericValue = num.tryParse(pinController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final minAmount = widget.minAmount ?? 50;
      showMinWarning = numericValue < minAmount && numericValue != 0;
    } else {
      showMinWarning = pinController.text.length < widget.inputLength && pinController.text.isNotEmpty;
    }
  }

  String get _warningMessage {
    if (widget.errorMessage != null) return widget.errorMessage!;
    
    if (widget.fieldType == InputFieldType.password) {
      return "Password is required";
    } else if (widget.fieldType == InputFieldType.amount) {
      final minAmount = widget.minAmount ?? 50;
      return "Minimum amount is ${widget.currency}$minAmount";
    } else {
      return "PIN must be ${widget.inputLength} digits";
    }
  }

  String get _currentTitle {
    if (widget.type == PinScreenType.set && isConfirm) {
      return "Confirm Payment PIN";
    }
    return widget.title;
  }

  String get _currentSubtitle {
    if (widget.type == PinScreenType.set && isConfirm) {
      return "Enter PIN again to confirm";
    }
    return widget.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? offWhiteBackground,
      appBar: widget.customAppBar as PreferredSizeWidget? ?? AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: primaryColor),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          _currentTitle,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.backgroundColor ?? offWhiteBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          children: [
            SizedBox(height: 65.h),
            
            // Subtitle
            Text(
              _currentSubtitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 15.h),
            
            // Input Field (PIN, Password, or Amount)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: widget.fieldType == InputFieldType.pin
                  ? AppPinCodeField(
                      controller: pinController,
                      length: widget.inputLength,
                      fillColor: widget.backgroundColor ?? offWhiteBackground,
                      inactiveColor: keyAColor,
                      activeColor: primaryColor,
                      selectedColor: primaryColor,
                    )
                  : widget.fieldType == InputFieldType.amount
                      ? TextField(
                          controller: pinController,
                          readOnly: true,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                          decoration: InputDecoration(
                            hintText: "${widget.currency}0.00",
                            hintStyle: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey[400],
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            filled: true,
                            fillColor: widget.backgroundColor ?? offWhiteBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                          ),
                        )
                      : TextField(
                      controller: pinController,
                      obscureText: widget.obscureText,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? "Enter password",
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        filled: true,
                        fillColor: widget.backgroundColor ?? offWhiteBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: keyAColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: keyAColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: errorColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _checkMinLimit();
                        });
                      },
                      onSubmitted: (value) => _handleSubmit(),
                    ),
            ),
            
            // Warning Message
            if (showMinWarning)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text(
                  _warningMessage,
                  style: theme.textTheme.bodySmall?.copyWith(color: errorColor),
                ),
              ),
            
            // Conditional spacing and keypad/button
            if (widget.fieldType == InputFieldType.pin && widget.showKeypad) ...[
              SizedBox(height: 120.h),
              
              // Custom Keypad (only for PIN fields)
              Expanded(
                child: CustomKeypad(
                  onKeyPressed: _onKeypadInput,
                ),
              ),
            ] else ...[
              SizedBox(height: 40.h),
              
              // Submit button for password fields or when keypad is disabled
              if (widget.fieldType == InputFieldType.password || !widget.showKeypad)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}