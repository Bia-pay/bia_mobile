import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/services/security_service.dart';
import '../../../../feature/dashboard/widgets/keypad.dart';
import '../../../../feature/dashboard/widgets/pin_lockout_overlay.dart';
import '../colors.dart';
import 'enhanced_pin_screen.dart';

class PinInputWidget extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final PinScreenType type;
  final InputFieldType fieldType;
  final int inputLength;
  final String? existingPin;
  final String? hintText;
  final bool showKeypad;
  final bool lockoutEnabled;
  final String currency;
  final Function(String val)? onPinConfirmed;
  final Function(String val)? onPinComplete;
  final VoidCallback? onForgotPin;
  final VoidCallback? onBiometricAction;
  final VoidCallback? onSupportTap;
  final IconData? biometricIcon;
  final Color? textColor;
  final Color? dotColor;
  final Color? keyColor;
  final double? keypadHeight;

  const PinInputWidget({
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
    this.currency = '₦',
    this.onPinConfirmed,
    this.onPinComplete,
    this.onForgotPin,
    this.onBiometricAction,
    this.onSupportTap,
    this.biometricIcon,
    this.textColor,
    this.dotColor,
    this.keyColor,
    this.keypadHeight,
  });

  @override
  ConsumerState<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends ConsumerState<PinInputWidget> {
  String _input = "";
  String _firstInput = "";
  bool _isConfirming = false;
  String _currentSubtitle = "";
  
  PinLockoutStatus? _lockoutStatus;
  Timer? _lockoutTimer;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _currentSubtitle = widget.subtitle;
    _textController = TextEditingController();
    if (widget.lockoutEnabled) _checkLockout();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkLockout() async {
    final status = await SecurityService.getLockoutStatus();
    if (mounted) {
      setState(() {
        _lockoutStatus = status;
        if (status.isLocked && !status.isPermanentlyFrozen) _startLockoutTimer();
      });
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final status = await SecurityService.getLockoutStatus();
      if (mounted) {
        setState(() {
          _lockoutStatus = status;
          if (!status.isLocked) timer.cancel();
        });
      }
    });
  }

  void _addDigit(String value) {
    if (_lockoutStatus?.isLocked ?? false) return;
    
    // For amount, we don't strictly enforce inputLength the same way
    if (widget.fieldType == InputFieldType.amount) {
      if (value == "." && _input.contains(".")) return;
      if (_input.contains(".") && _input.split(".").last.length >= 2) return; // Limit to 2 decimal places
    } else if (_input.length >= widget.inputLength) {
      return;
    }
    
    setState(() {
      if (_input == "0" && value != ".") {
        _input = value;
      } else {
        _input += value;
      }
      _textController.text = widget.fieldType == InputFieldType.amount ? _input : _input;
    });

    if (widget.fieldType != InputFieldType.amount && _input.length == widget.inputLength) {
      _handleInputCompletion();
    }
  }

  void _removeDigit() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _textController.text = _input;
    });
  }

  void _handleInputCompletion() {
    if (widget.type == PinScreenType.set) {
      if (!_isConfirming) {
        _firstInput = _input;
        setState(() {
          _isConfirming = true;
          _input = "";
          _currentSubtitle = "Confirm your PIN";
        });
      } else {
        if (_input == _firstInput) {
          widget.onPinConfirmed?.call(_input);
        } else {
          _showError("PINs do not match. Please try again.");
          setState(() {
            _isConfirming = false;
            _input = "";
            _currentSubtitle = widget.subtitle;
          });
        }
      }
    } else if (widget.type == PinScreenType.verify || widget.type == PinScreenType.confirm) {
      widget.onPinComplete?.call(_input);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: errorColor));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPinMode = widget.fieldType == InputFieldType.pin;
    final screenH = MediaQuery.of(context).size.height;
    final isSmallScreen = screenH < 800;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title.isNotEmpty) ...[
          Text(widget.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: widget.textColor ?? primaryColor)),
          SizedBox(height: 8.h),
        ],
        Text(_currentSubtitle, style: theme.textTheme.bodyMedium?.copyWith(color: (widget.textColor ?? grey).withOpacity(0.7))),
        SizedBox(height: isTablet ? 16 : (isSmallScreen ? 16.h : 32.h)),

        isPinMode ? _buildPinDots() : _buildTextField(),

        SizedBox(height: isTablet ? 16 : (isSmallScreen ? 16.h : 32.h)),

        if (widget.showKeypad)
          SizedBox(
            height: widget.keypadHeight ?? (isTablet ? 260.0 : 350.h),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          child: CustomGridKeypad(
                            onNumberPressed: _addDigit,
                            textColor: widget.textColor ?? primaryColor,
                            keyColor: widget.keyColor,
                            leftAction: (_input.isEmpty && widget.onBiometricAction != null)
                                ? ActionKey(
                                    child: Icon(
                                      widget.biometricIcon ?? Icons.fingerprint,
                                      color: Colors.white,
                                      size: isTablet ? 22.0 : 28.sp,
                                    ),
                                    backgroundColor: primaryColor,
                                    onTap: widget.onBiometricAction!,
                                  )
                                : ActionKey(
                                    child: Icon(Icons.check, color: Colors.white, size: isTablet ? 20.0 : 24.sp),
                                    backgroundColor: primaryColor,
                                    onTap: _handleInputCompletion,
                                  ),
                            rightAction: ActionKey(
                              child: Icon(Icons.backspace, color: primaryColor, size: isTablet ? 20.0 : 24.sp),
                              backgroundColor: (widget.textColor ?? primaryColor).withOpacity(0.1),
                              onTap: _removeDigit,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_lockoutStatus?.isLocked ?? false)
                      Positioned.fill(
                        child: PinLockoutOverlay(
                          isFrozen: _lockoutStatus!.isPermanentlyFrozen,
                          remainingTime: _lockoutStatus!.remainingTime,
                          onSupportTap: widget.onSupportTap,
                        ),
                      ),
                  ],
                );
              }
            ),
          ),

        if (widget.onForgotPin != null && !(_lockoutStatus?.isLocked ?? false))
          Padding(
            padding: EdgeInsets.only(top: isTablet ? 8 : 6.h),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgotPin,
                child: Text(
                  'Forgot Password?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: widget.textColor ?? primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 12.0 : 12.sp,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPinDots() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.inputLength, (index) {
        final filled = index < _input.length;
        final double dotSize = isTablet ? 14.0 : 16.w;
        final double marginH = isTablet ? 8.0 : 8.w;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(horizontal: marginH),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? primaryColor : Colors.transparent,
            border: Border.all(
              color: filled
                  ? (widget.dotColor ?? primaryColor)
                  : (widget.dotColor ?? grey).withOpacity(0.3),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTextField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: TextField(
        controller: _textController,
        readOnly: widget.showKeypad,
        enabled: !(_lockoutStatus?.isLocked ?? false),
        obscureText: widget.fieldType == InputFieldType.password,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: widget.textColor ?? primaryColor),
        decoration: InputDecoration(
          hintText: widget.hintText ?? "",
          hintStyle: TextStyle(color: (widget.textColor ?? grey).withOpacity(0.3)),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: (widget.textColor ?? primaryColor).withOpacity(0.2))),
        ),
      ),
    );
  }
}
